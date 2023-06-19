#!/bin/bash
#1031349 Dirk Roosendaal - 1034335 Yvonne Maan


csvFile=""
queueFile="ready_queue.txt"
arivalFile="to_be_arived.txt"

# method for: add processes to the end of the queueFile (returns nothing)
enqueue() { 
    echo "$1" >> "$queueFile"
}

# method for: taking/returning the head process of the queue
# detials:    it also subtracts 1 execution time because that has been completed (in this quantum), 
#             then it returns this process (or "none" if there is no task)
dequeue() {
    if [ -s "$queueFile" ]; then
        first_line=$(head -n 1 "$queueFile")
        sed -i '1d' "$queueFile"
        IFS=',' read -r name remaining_time <<< "$first_line"
        new_time=$((remaining_time - 1))
        echo "$name,$new_time"
    else
        echo "none"
    fi
    return 0
}

# method for: adding processes to the arival File, this files containts all the proceses that havent arived yet 
# details:    we are using a sperate file for this isntead of the given file of the user, thatway we can remove any arrived processes from this file
#             (they obviously cant be added to the queue imidiatly if they didnt arive yet)   (returns nothing)
setArival(){
    echo "$1" >> "$arivalFile"
}

# method for: adding all processes arived processes to the queue
# details:    if the arival start_time matches the given quantum, then it adds it
#             it also removes the starting time because thats not needed anymore inside queue
#             (returns nothing)
enqueueReadyArivals(){
    lineIndex=1
    movedOver=0
 
    while IFS="," read -r name start_time execution_time; do
        if [ "$1" = "$start_time" ]; then #if the quantum ($1) is the same as the start_time, then add it in to the queue, (without the start_time, you dont need the start_time insde the queue anymore)
            enqueue "$name,$execution_time"
            sed -i "$((lineIndex - movedOver))d" "$arivalFile"
            ((movedOver++))
        fi
        ((lineIndex++))
    done < $arivalFile
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
touch "$arivalFile"

while IFS="," read -r name start_time execution_time; do

    if [ "$firstIterationDone" = false ]; then
        #the first iteration will be skipped because in csv the first line / head is always the different names of the different columbs
        echo ""
        
    else
        if ! [[ "$start_time" =~ ^[0-9]+$ ]]; then #checking if starting time is really an int
            echo "starting time of: $start_time is not a valid number"
            rm $arivalFile
            exit 1
        elif ! [[ "$execution_time" =~ ^[0-9]+$ ]]; then # checking if execution time is really an int
            echo "execution time of: $execution_time is not a valid number"
            rm $arivalFile
            exit 1
        elif [ "$start_time" -lt 0 ]; then # checking if starting time is 0 or more
            echo "starting time of: $start_time is not possible"
            rm $arivalFile
            exit 1
        elif [ "$execution_time" -le 0 ]; then # checking if execution time is more then
            echo "execution time of: $execution_time is not possible"
            rm $arivalFile
            exit 1
        fi
        
        setArival "$name,$start_time,$execution_time"
    fi
    firstIterationDone=true
done < $csvFile



# from here the "CPU" starts running, this loop simulates that
# every iteration of the loop is a Quantum
Quantum=0
previouslyDequeued="none"
touch "$queueFile"
while true; do
    if [ ! -s $queueFile ] && [ ! -s $arivalFile ] && [ $Quantum -gt 0 ] && [ "$previouslyDequeued" == "none" ]; then
        #echo "stoped the simulation at Quantum: $Quantum"
        rm $arivalFile
        rm $queueFile
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
    #step 4, print what is happening to the user
    if [ "$previouslyDequeued" != "none" ]; then
        
        IFS=',' read -r name new_time <<< "$previouslyDequeued"
        echo "$name is using the CPU"
        if [ ! "$new_time" -gt 0 ]; then 
            echo "Process $name terminated"
            previouslyDequeued="none"
        fi
    else
        echo "idle"
    fi

    ((Quantum++))
done


