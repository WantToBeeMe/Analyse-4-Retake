#!/bin/bash
#1031349 Dirk Roosendaal
#.. .. ..

echo "simulator starting"


#the csv are made by me to test
# wrong1 = duplication of name (still awaiting response of teacher if this is really wrong)
# wrong2 = negative starting time
# wrong3 = non positive exection time
csvFile=""

#checking if you enter in `-file`
#if you dont enter `-file` the program will imidiatly stop with an error message: `Invallid argument $1`
#if you do enter `-file` it will put the second argument in csvFile  (no matter what it is, it will be checked later)
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -file) #in case of -file   do this
            csvFile="$2"
            shift
            shift
            ;;
        *)  #in case of anything else, do this
            echo "Invalid argument: $1"
            exit 1 
            ;;
    esac 
done

#checking if the given file really exists, if not the program will imidiatly stop 
# if you didnt give anything it will give the error message: `No file specified.`
# or if you gave a file that doesnt exist it will give the error message: `File not found: $csvFile`
if [ -z "$csvFile" ]; then
    echo "No file specified."
    exit 1
fi
if [ ! -f "$csvFile" ]; then
    echo "File not found: $csvFile"
    exit 1
fi


#checkeing if the given file is corectly formatted. 
# WORK IN PROGRESS
# corectly formatted if    `name , startTime , processTime`
# -> where name cant be duplicated                              #(should be asked to the teacher if this is needed / required)
# -> where startTime should be an Int:  startTime >= 0          #time start at 0, so starting below that is not posible                         (should exist with error : `start time of $ is imposible`)
# -> where processTime should be an Int:    processTime > 0     #you cant have a proces that doesnt take any time, then its not even a process  (should exist with error : `process time of $ is imposible`)


while IFS=',' read -r name start_time execution_time; do
  
    echo $name - $start_time - $execution_time
   
done < "$csvFile"








# the assignment in a nutshel 

# this simulation will simule the Round Robin Algorithm        (note: quantum is a tiny time period)
# (each proces uses the CPU for a quantum and then its added to the back of the queue again, untill it has had enough quantums that its done) 
# when done, its execution time is then permanently removed from the scheduling 
#
# you will have several "fake processes" to schedule
# this program should decide when one of the "fake processes" needs to run
# each ëxecition"time for each quantum will be represented only from a printout (afther the print it will continue with the next running process)
#
# for example the following data
#      t = time in quantums
#     start t = time that the proces arives at cp (so when it should start (at witch queantum it should start))
#     execution t = the amount of quantums it takes for it to finish
#  Proces Name | Start t | execution t 
#      P1      |    0    |     4         #should start imidiatly, and take 4 quantums to finish
#      P2      |    1    |     2
#      P3      |    3    |     1         #should start at the 3th quantum, but finish imidiatly (because it only needs 1 quantum)
#    
#        t=0 
# P1 is using the CPU
#        t=1
# P2 is using the CPU
# P1 is using the CPU
#        t=2
# P2 is using the CPU
# Process P2 terminated
#        t=3
# p3 is using the CPU
# Process P3 terminated
# P1 is using the CPU
#        t=4
# P1 is using the CPU
# Procces P1 terminated

# note that the t=0, t=1, t=n shoudnt be printed, its just here for clarity
