# xHiPP

This code is a new design for Hierarchical Point Placement Strategy (HiPP), called
eXtend HiPP (xHiPP). xHiPP is a Multidimensional Projection capable of present several levels
of data details.

## Getting Started

These instructions will get you a copy of the project to run on your local machine for development and testing purposes. 

### Prerequisites

* [R](https://www.r-project.org/) - Download and install the R latest version
* [RStudio](https://www.rstudio.com/products/rstudio/download/) - Download and install the RStudio latest version
* [R packages](https://www.r-bloggers.com/installing-r-packages/) - Open RStudio and follow the previous link instructions to install these packages:  "jsonlite", "mp", "doParallel", "tm", "topicmodels", "SnowballC", "shiny", "mime", "stringr"

### Installing

```
After downloading and discompacting xHiPP directory, copy from run/ directory files: run.R, 
RUN_SERVER and RUN_CLIENT

obs.: If you are using Windows, pleace take .bat files. If you are using Unix-like, take .sh ones
```

```
Edit xHIPP.PATH variable into run.R to your correspondent xHiPP directory path. 
```

```
Edit RUN_SERVER_PATH variable into RUN_SERVER to your correspondent run.R path.
```

```
If it is necessary, edit USE_CHROME and SERVER_TCP_PORT variables into RUN_CLIENT to your desaired 
configuration.
```

## Running the tests

First and foremost, execute the RUN_SERVER script. After this, just execut RUN_CLIENT to open your browse showing xHiPP.


