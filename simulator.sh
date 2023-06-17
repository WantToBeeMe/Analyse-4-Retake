#!/bin/bash
#1031349 Dirk Roosendaal
#.. .. ..

echo "simulator starting"
csvFile=""
queueFile="ready_queue.txt"
arivalFile="to_be_arived.txt"

queueFileCreated=false
enqueue() {
    queueFileCreated=true
    echo "$1" >> "$queueFile"
}

dequeue() {
    #thsi checks if the file existst, all teh FileCreated booleans should be deleted and the deleted function should use this instead
    if [ "$queueFileCreated" = true ]; then
        echo "none"
    elif [ -s "$queueFile" ]; then
        first_line=$(head -n 1 "$queueFile")
        sed -i '1d' "$queueFile"
        #IFS=',' read -r name remaining_time windows_test <<< "$first_line"
        IFS=',' read -r name remaining_time <<< "$first_line"
        new_time=$((remaining_time - 1))
        #echo "$name,$new_time,$windows_test"
        echo "$name,$new_time"
    else
        echo "none"
    fi
    return 0
}

#functionst that handel the arival File, this files containts all the proceses that havent arived yet (they cant be in the queue yet, becasue they obviously didnt arive)
#every Quantum the function `$(enqueueReadyArivals "$Quantum")` should be called to let proceses arive that should arive
arivalFileCreated=false
setArival(){
    arivalFileCreated=true
    echo "$1" >> "$arivalFile"
}
enqueueReadyArivals(){
    lineIndex=1
    movedOver=0
    if [ "$arivalFileCreated" = true ]; then
        #while IFS="," read -r name start_time execution_time windows_test; do
        while IFS="," read -r name start_time execution_time; do
            if [ "$1" = "$start_time" ]; then
                #enqueue "$name,$execution_time,windows_test"
                enqueue "$name,$execution_time"
                sed -i "$((lineIndex - movedOver))d" "$arivalFile"
                ((movedOver++))
            fi
            ((lineIndex++))
        done < $arivalFile
    fi
}


stopSimulation(){
    # Remove the queue file once all tasks are processed
     if [ "$arivalFileCreated" = true ]; then
        rm "$arivalFile"
     fi

     if [ "$queueFileCreated" = true ]; then 
        rm "$queueFile"
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
#while IFS="," read -r name start_time execution_time windows_test; do
while IFS="," read -r name start_time execution_time; do

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
previouslyDequeued="none"
while true; do
    if [ -s "$QueueFile" ] && [ -s "$arivalFile" ]; then #this should work, it doesnt for windows though
    #if [ "$Quantum" -eq 15 ]; then
        echo "stoped the simulation at $Quantum"
        break
    fi

    #each quantum these steps should be done
    #step 1: check for arivals, add to queue
    $(enqueueReadyArivals "$Quantum")
    #step 2: check for previous dequeued if it needs requeuing, else print the termination
    if [ "$previouslyDequeued" != "none" ]; then
        $(enqueue "$previouslyDequeued")
    fi
    #step 3, dequeue a new one
    previouslyDequeued=$(dequeue)

    if [ "$previouslyDequeued" != "none" ]; then
        #IFS=',' read -r name new_time windows_test <<< "$previouslyDequeued"
        IFS=',' read -r name new_time <<< "$previouslyDequeued"
        echo "$name is using the CPU"
        if [ ! "$new_time" -gt 0 ]; then 
            echo "Process $name terminated"
            previouslyDequeued="none"
        fi
    fi

    ((Quantum++))
done

$(stopSimulation)

