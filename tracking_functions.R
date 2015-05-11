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
		end_x = plot_size*.95
		if (start_position[2] > plot_size/2) {
			# starts high, end low
			end_y = runif(1, min=plot_size*0.05, max=plot_size/2)
		} else {
			#start low, end high
			end_y = runif(1, min=plot_size/2, max=plot_size*.95)
		}
	} else if (start_position[1] == 1) {
		# x=1: starts on right, ends on left
		end_x = plot_size*.05
		if (start_position[2] > plot_size/2) {
			# starts high, end low
			end_y = runif(1, min=plot_size*.05, max=plot_size/2)
		} else {
			#start low, end high
			end_y = runif(1, min=plot_size/2, max=plot_size*.95)
		}
	} else if (start_position[2] == 0) {
		# y=0: starts on bottom, ends on top
		end_y = plot_size*.95
		if (start_position[1] > plot_size/2) {
			# starts high, end low
			end_x = runif(1, min=plot_size*.05, max=plot_size/2)
		} else {
			#start low, end high
			end_x = runif(1, min=plot_size/2, max=plot_size*.95)
		}
	} else {
		# y=1: starts on top, ends on bottom
		end_y = plot_size*.05
		if (start_position[1] > plot_size/2) {
			# starts high, end low
			end_x = runif(1, min=plot_size*.05, max=plot_size/2)
		} else {
			#start low, end high
			end_x = runif(1, min=plot_size/2, max=plot_size*.95)
		}
	}
	rval = c(end_x, end_y)
	return(rval)
}

agent1_movement <- function(num_steps, plot_size) {
	# intialize starting coordinates
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

two_agent_movement <- function(method, num_steps, agent2_range, plot_size) {
	# method:		character of whether or not to follow, cutoff, or random
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
	if (method %in% c("follow", "cutoff")) {
		# start near the middle
		x = runif(1, min=plot_size/3, max=3*plot_size/3)
		y = runif(1, min=plot_size/3, max=3*plot_size/3)
		# make note of agent 1's ending position
		a1_x_end = agent1_df[nrow(agent1_df), "x_pos"]
		a1_y_end = agent1_df[nrow(agent1_df), "y_pos"]
		# pick a random step to initiate action even if agent 1 is far away
		initiate = runif(n=1, min=2*num_steps/5, max=4*num_steps/5)
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
		if (method %in% c("follow", "cutoff")) {
			# check if agent 1 is currently in range
			a1_x <- agent1_df[i, "x_pos"]
			a1_y <- agent1_df[i, "y_pos"]
			in_range <- ((x + plot_size * agent2_range) >= a1_x &
					(x - plot_size * agent2_range) <= a1_x &
					(y + plot_size * agent2_range) >= a1_y &
					(y - plot_size * agent2_range) <= a1_y)

			if (in_range | i > initiate) {
				if (method == "follow") {
					# initiate following sequence
					# make a step size in the direct agent 1 was previously located
					i_prev = max(1, i-1)
					x_dif <- (agent1_df[i_prev, "x_pos"] - x)
					y_dif <- (agent1_df[i_prev, "y_pos"] - y)
					total_distance_away <- sqrt(x_dif^2 + y_dif^2)
					x_change <- x_dif * step_size/total_distance_away
					y_change <- y_dif * step_size/total_distance_away
					# set x and y
					x <- x + x_change
					y <- y + y_change

					# update dataset to note new status states
					agent2_df[i, "status"] <- "pursue"
					agent1_df[i, "status"] <- "evade"
				} else {
					# initiate cutoff sequence
					if (i > num_steps-2) {
						x <- a1_x_end
						y <- a1_y_end
					} else {
						# make a step in the direction agent 1 wants to go
						x_dif <- (a1_x_end - x)
						y_dif <- (a1_y_end - y)
						total_distance_away <- sqrt(x_dif^2 + y_dif^2)
						# use the modified step size to reach target faster
						pace = max((num_steps - i - 1), 1)
						big_step_size = max(step_size, (total_distance_away / pace))
						x_change <- x_dif * big_step_size / total_distance_away
						y_change <- y_dif * big_step_size / total_distance_away
						# update new x and y
						x <- x + x_change
						y <- y + y_change
					}
					# update dataset to note new status states
					agent2_df[i, "status"] <- "cutoff"
					agent1_df[i, "status"] <- "cutoff"
				}
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


