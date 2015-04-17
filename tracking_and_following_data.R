library(ggplot2)
library(png)
library(animation)
library(grid)

set.seed(1234)

# load tracking functions
source("/Users/robert/Documents/UMN/5561_CV/Project/code/tracking_functions.R")

# plot a few simulations
save_simulations <- function(num_simulations, follow, background_filename, num_steps=50, plot_size=1) {
	Sys.unsetenv("PATH")
	Sys.setenv(PATH='/opt/local/bin')
	background <- readPNG(paste0(background_filename, ".png"))
	g <- rasterGrob(background, interpolate=TRUE)
	ani.options(nmax=num_steps)

	# run simulations
	for (sim in 1:num_simulations) {
		filename_root <- paste0(ifelse(follow,"follow_","random_"),
			background_filename,
			sim)
		# build data
		agent2_range <- runif(1, min=.2, max=.3) # randomize visibility a little
		DF <- two_agent_movement(follow, num_steps, agent2_range, plot_size)
		# save data in case needed later
		write.csv(DF,
			file=paste0(filename_root, ".csv"),
			row.names=FALSE)
		# create gif and save it
		gif_name <- paste0(filename_root, ".gif")
		saveGIF({
			for (i in 1:num_steps) {
				print(
					ggplot(data = DF[DF$step == i,],
						aes(x=x_pos, y=y_pos, colour=agent)) +
						coord_cartesian(xlim=c(0,plot_size),ylim=c(0,plot_size)) +
						labs(x=NULL, y=NULL, colour=NULL, title=NULL) +
						theme(panel.grid = element_blank(),
							panel.background = element_blank(),
							panel.border=element_blank(),
							line = element_blank(),
							text = element_blank(),
							title = element_blank(),
							plot.margin=unit(c(-.5,-.5,-.5,-.5),"lines"),
							panel.margin = unit(0,"null"),
							axis.ticks.length = unit(0,"null"),
							axis.ticks.margin = unit(0,"null"),
							axis.text=element_blank(),
							legend.position = "none") +
						annotation_custom(g, xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf) +
						geom_point(size = 15)
				)
			}
		}, interval = 0.01,
			movie.name = gif_name)
	}
}

# run a few simulations
save_simulations(num_simulations=10,
	follow=TRUE,
	background_filename="beach")

save_simulations(num_simulations=10,
	follow=TRUE,
	background_filename="forest")

save_simulations(num_simulations=5,
	follow=FALSE,
	background_filename="forest")

save_simulations(num_simulations=5,
	follow=FALSE,
	background_filename="beach")
