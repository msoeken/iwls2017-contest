# IWLS 2017 Programming Contest: "Y Logic Synthesis"

In 2017, we will organize a programming contest at the [International Workshop on Logic & Synthesis](http://www.iwls.org/iwls2017/) (IWLS).  To participate, please follow these steps:

1. Read the [contest description](contest.pdf).

2. Write an algorithm that translates benchmarks in either Verilog, Aiger, or Blif format into YIG files.  Some benchmarks for training are available in the *examples* directory.

3. We will send additional contest benchmarks on **April 26, 2017**.  These will be used to evaluate your algorithms.

4. You need to submit your binary or source code and the resulting YIG files for the contest benchmarks until **May 3, 2017**.  Please send everything via email to [Mathias Soeken](https://github.com/msoeken).  We must be able to reproduce your results on our machines within a timeout of 10 minutes.

5. We will submit the generated YIG files from your submissions until **May 10, 2017** and announce all the results on this webpage.

6. The submissions are rated according to the number of gates in the YIGs.  If for some benchmark no YIG exists or the algorithm reaches the timeout limit, we take the worst case size over all submissions and multiply it by 1.5.  If for some benchmark an incorrect YIG exists, we take the worst case size over all submissions and multiply it by 2.

7. You are encouraged to share your source code with the IWLS community, but it's not required or has any effect on the rating.  If you want to share, you can either point us to an online repository that we will link to this and the IWLS webpage.  If you prefer to share the source code only among the IWLS participants, we will copy your code onto the proceeding pen drives.

If you have any question, please create an [issue](https://github.com/msoeken/iwls2017-contest/issues).

## Awards

1. Place: 1200 USD

2. Place: 1000 USD

3. Place: 800 USD

Awarded students are required to participate at IWLS and present their algorithms and results.

## Supplemental material

* [Pre-fascicle to *The Art of Computer Programming* Section 7.1.1.](http://www-cs-faculty.stanford.edu/~uno/fasc0b.ps.gz), more information on the *Y*-function is described in Exercise 67.
