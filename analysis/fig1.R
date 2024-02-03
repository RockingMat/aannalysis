library(tidyverse)
library(ggtext)

x <- rbeta(1000,0.9,10) %>%
  enframe()

x %>%
  arrange(-value) %>%
  mutate(i = row_number()) %>%
  # filter(value > 0.1) %>%
  ggplot(aes(value)) +
  geom_density(color="#d95f02") +
  # annotate(
  #   geom = "curve", xend = 0.38, yend = 0.8, x = 0.33, y = 0.26,
  #   curvature = .2, arrow = arrow(length = unit(2, "mm"))
  # ) +
  # annotate(
    # geom = "curve", xend = 0.38, yend = 0.8, x = 0.33, y = 0.26,
    # curvature = .3, arrow = arrow(length = unit(2, "mm"))
  # ) +
  # geom_richtext(
  #   x = 0.4, y=1.4,
  #   label = "a beautiful<br>five days",
  #   family="Times"
  # ) +
  # annotate(
  #   geom = "label",
  #   x = 7.53, y = 0.35,
  #   label = str_wrap("Chance Performance", width = 25),
  #   hjust = "left",
  #   family = "Times",
  #   fontface = "italic",
  #   lineheight = 1,
  #   size = 5
  # ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank()
  )

ggsave("paper/figure1.svg", device = "svg", height = 3.31, width = 4.61, dpi=300)



  
