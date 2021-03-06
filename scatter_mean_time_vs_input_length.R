library('stats')
library('reshape2')
library('ggplot2')

print("Generating Scatter Plot for mean processing time vs file size");

source("read-json-data.R")
source("fte-theme.R")

millis_in_nano <- 10000000

command_line_args <- commandArgs(trailingOnly = TRUE)

num_args <- length(command_line_args)

if (num_args < 2) {
    stop("Not enough parameters specified.")
}

files <- command_line_args[2:num_args]
input_file_name_full <- command_line_args[1]

data_frame <- read_json_data(files)
data_frame <- data_frame[data_frame[["inputFile"]] == input_file_name_full,]

scatter_input_ids <- unique(c(as.character(data_frame[["inputId"]])))
number_unique_ids <- length(scatter_input_ids)
scatter_means <- numeric(number_unique_ids)
scatter_lengths <- numeric(number_unique_ids)
scatter_ids <- character(number_unique_ids)

print(paste("Found", number_unique_ids, "unique input IDs."))

for (i in 1:number_unique_ids) {

    print(paste(i, "/", number_unique_ids))

    id = scatter_input_ids[i]

    data_frame_subset <- data_frame[data_frame[["inputId"]] == id, ]

    elapsed <- data_frame_subset[, "elapsed"] / millis_in_nano

    mean_elapsed <- mean(elapsed)
    length <- data_frame_subset[1, "inputLength"]

    scatter_means[i] <- mean_elapsed
    scatter_lengths[i] <- length
    scatter_ids[i] <- id
}

scatter_data_frame = data.frame(scatter_ids, scatter_means, scatter_lengths)
names(scatter_data_frame) <- c("inputId", "mean", "length")

scatter_data_frame <- scatter_data_frame[complete.cases(scatter_data_frame), ]

number_of_points <- nrow(scatter_data_frame)

print(paste("Generated", number_of_points, "datapoints."))

print(paste("Removing rows not within one standard deviation of the mean."))

scatter_standard_deviation <- sd(scatter_data_frame[["mean"]])
scatter_mean <- mean(scatter_data_frame[["mean"]])

scatter_data_frame <- scatter_data_frame[scatter_data_frame[["mean"]] < scatter_mean + scatter_standard_deviation & scatter_mean - scatter_standard_deviation < scatter_data_frame[["mean"]], ]

print(paste("Removed", number_of_points - nrow(scatter_data_frame), "rows."))

number_of_points <- nrow(scatter_data_frame)

print("Generating Scatter Plot")

plot <- ggplot(scatter_data_frame)
plot <- plot + geom_point(aes(x = length, y = mean), color = "#c0392b", alpha = 0.2)
plot <- plot + geom_smooth(aes(x = length, y = mean), alpha=0.25, color="black", fill="black")
plot <- plot + scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x), labels = scales::trans_format("log10", scales::math_format(10^.x)))
plot <- plot + labs(x = "Length of Input", y = "Mean Processing Time (ms)", title = paste("Mean Processing time vs Input Length for", input_file_name_full))
plot <- plot + fte_theme()

ggsave("graphs/scatter_mean_time_vs_input_length.png", dpi = 1200, width = 8, height = 6, type = "cairo")

print("Done.")
