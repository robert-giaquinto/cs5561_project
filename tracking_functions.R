library(ggplot2)
library(png)
library(animation)
library(grid)

set.seed(1234)

spawn_agent1 <- function(plot_size) {
	start_side = sample(1:4, 1)
	if (start_side %in% c(1, 3)) {
		start_y = rbinom(1, 1, .5) # y position is 0 or 1
		start_x = runif(1, min=0, max=plot_size) # x position is uniform
	} else {
		start_y = runif(1, min=0, max=plot_size) # y position is uniform
		start_x = rbinom(1, 1, .5) # x position is 0 or 1
	}
	rval = c(start_x, start_y)
	return(rval)

}

end_agent1 <- function(start_position, plot_size) {
	if (start_position[1] == 0) {
		# x=0: starts on left, ends on right
		end_x = 1
		if (start_position[2] > plot_size/2) {
			# starts high, end low
			end_y = runif(1, min=0, max=plot_size/2)
		} else {
			#start low, end high
			end_y = runif(1, min=plot_size/2, max=plot_size)
		}
	} else if (start_position[1] == 1) {
		# x=1: starts on right, ends on left
		end_x = 0
		if (start_position[2] > plot_size/2) {
			# starts high, end low
			end_y = runif(1, min=0, max=plot_size/2)
		} else {
			#start low, end high
			end_y = runif(1, min=plot_size/2, max=plot_size)
		}
	} else if (start_position[2] == 0) {
		# y=0: starts on bottom, ends on top
		end_y = 1
		if (start_position[1] > plot_size/2) {
			# starts high, end low
			end_x = runif(1, min=0, max=plot_size/2)
		} else {
			#start low, end high
			end_x = runif(1, min=plot_size/2, max=plot_size)
		}
	} else {
		# y=1: starts on top, ends on bottom
		end_y = 0
		if (start_position[1] > plot_size/2) {
			# starts high, end low
			end_x = runif(1, min=0, max=plot_size/2)
		} else {
			#start low, end high
			end_x = runif(1, min=plot_size/2, max=plot_size)
		}
	}
	rval = c(end_x, end_y)
	return(rval)
}

agent1_movement <- function(num_steps, plot_size) {
	# intialize starting coordinatess
	start <- spawn_agent1(plot_size)
	end <- end_agent1(start, plot_size)
	# find slope
	x_slope <- (end[1] - start[1])/(num_steps-1)
	y_slope <- (end[2] - start[2])/(num_steps-1)
	rval <- data.frame(step=1:num_steps,
		x_pos = rep(NA, num_steps),
		y_pos = rep(NA, num_steps),
		agent=factor("one"),
		status=as.character("safe"),
		stringsAsFactors=FALSE)
	for (i in 1:num_steps) {
		rval[i, "x_pos"] <- start[1] + (i-1) * x_slope
		rval[i, "y_pos"] <- start[2] + (i-1) * y_slope
	}
	return(rval)
}

two_agent_movement <- function(follow, num_steps, agent2_range, plot_size) {
	# follow:		boolean whether or not to follow
	# num_steps:	number of steps in the simulation, higher=more granularity
	# agent2_range:	used to find distance that agent2 can perceive agent1
	#				input as a percent (of the plotting window)
	# plot_size:	size of plotting window

	# create agent1's data
	agent1_df <- agent1_movement(num_steps, plot_size)

	# initialize agent2's dataframe
	agent2_df = data.frame(step=1:num_steps,
		x_pos=rep(NA, num_steps),
		y_pos=rep(NA, num_steps),
		agent=factor("two"),
		status=as.character("random"),
		stringsAsFactors=FALSE)

	# initialize starting position
	if (follow) {
		# start near the middle
		x = runif(1, min=plot_size/4, max=3*plot_size/4)
		y = runif(1, min=plot_size/4, max=3*plot_size/4)
	} else {
		# just start anywhere
		x = runif(1, min=0, max=plot_size)
		y = runif(1, min=0, max=plot_size)
	}
	step_size <- plot_size/num_steps
	# simulate motion
	for (i in 1:num_steps) {
		# set x and y positions based on last known information (or initialization)
		agent2_df[i, "x_pos"] <- x
		agent2_df[i, "y_pos"] <- y
		if (follow) {
			# check if agent 1 is currently in range
			a1_x <- agent1_df[i, "x_pos"]
			a1_y <- agent1_df[i, "y_pos"]
			in_range <- ((x + plot_size * agent2_range) >= a1_x &
					(x - plot_size * agent2_range) <= a1_x &
					(y + plot_size * agent2_range) >= a1_y &
					(y - plot_size * agent2_range) <= a1_y)
			if (in_range) {
				# make a stand step size in the direct agent 1 is
				# currently located
				x_dif <- (a1_x - x)
				y_dif <- (a1_y - y)
				total_distance_away <- sqrt(x_dif^2 + y_dif^2)
				x_change <- x_dif * step_size/total_distance_away
				y_change <- y_dif * step_size/total_distance_away
				# set x and
				x <- x + x_change
				y <- y + y_change

				# update dataset to note new status states
				agent2_df[i, "status"] <- "pursuing!"
				agent1_df[i, "status"] <- "evading!"
			} else {
				# move randomly
				x <- x + sign(rnorm(1))*step_size
				y <- y + sign(rnorm(1))*step_size
			}
		} else {
			# move randomly
			x <- x + sign(rnorm(1))*step_size
			y <- y + sign(rnorm(1))*step_size
		}
	}
	rval <- rbind(agent1_df, agent2_df)
	return(rval)
}


