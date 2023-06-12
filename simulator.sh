#!/bin/bash
#1031349 Dirk Roosendaal
#.. .. ..

echo "simulator starting"
csvFile=""
queueFile="ready_queue.txt"
arivalFile="to_be_arived.txt"

queueFileCreated=false
enqueue() {
    echo "$1" >> "$queueFile"
    queueFileCreated=true
}
#task=$(dequeue)
dequeue() {
    if [ -s "$queueFile" ]; then
        first_line=$(head -n 1 "$queueFile")
        sed -i '1d' "$queueFile"
        echo "$queueFile"
    else
        echo "Queue is empty."
    fi
}

#functionst that handel the arival File, this files containts all the proceses that havent arived yet (they cant be in the queue yet, becasue they obviously didnt arive)
#every Quantum the function `$(enqueueReadyArivals "$Quantum")` should be called to let proceses arive that should arive
arivalFileCreated=false
setArival(){
    echo "$1" >> "$arivalFile"
    arivalFileCreated=true
}
enqueueReadyArivals(){
    lineIndex=1
    movedOver=0
    if [ "$arivalFileCreated" = true ]; then
        #while IFS="," read -r name start_time execution_time windows_test; do
        while IFS="," read -r name start_time execution_time; do
            if [ "$1" = "$start_time" ]; then
                enqueue "$name,$execution_time"
                #enqueue "$name,$execution_time,windows_test"
                sed -i "$((lineIndex - movedOver))d" "$arivalFile"
                ((movedOver++))
            fi
            ((lineIndex++))
        done < $arivalFile
    fi
}

stopSimulation(){
    # Remove the queue file once all tasks are processed
    if [ "$queueFileCreated" = true ]; then 
        rm "$queueFile"
    fi
    if [ "$arivalFileCreated" = true ]; then
        rm "$arivalFile"
    fi
}

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

#checking if the file is correctly formatted, and copying it over so we dont make any changes to this csv
firstIterationDone=false
while IFS="," read -r name start_time execution_time; do
#while IFS="," read -r name start_time execution_time windows_test; do

    if [ "$firstIterationDone" = false ]; then
        #the catagory names of the csv values, idk if whe should do anything with this
        echo "$name, $start_time, $execution_time"
        
    else
        if ! [[ "$start_time" =~ ^[0-9]+$ ]]; then #checking if starting time is really an int
            echo "starting time of: $start_time is not a valid number"
            $(stopSimulation)
            exit 1
        elif ! [[ "$execution_time" =~ ^[0-9]+$ ]]; then # checking if execution time is really an int
            echo "execution time of: $execution_time is not a valid number"
            $(stopSimulation)
            exit 1
        elif [ "$start_time" -lt 0 ]; then # checking if starting time is 0 or more
            echo "starting time of: $start_time is not possible"
            $(stopSimulation)
            exit 1
        elif [ "$execution_time" -le 0 ]; then # checking if execution time is more then
            echo "execution time of: $execution_time is not possible"
            $(stopSimulation)
            exit 1
        fi
        #setArival "$name,$start_time,$execution_time,windows_test"
        setArival "$name,$start_time,$execution_time"
    fi
    firstIterationDone=true
done < $csvFile

Quantum=0
while true; do
    #this instead should check if the arival and the queue files are empty
    if [ "$Quantum" -eq 10 ]; then
        break
    fi

    $(enqueueReadyArivals "$Quantum")
    ((Quantum++))
done


#$(stopSimulation)



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
