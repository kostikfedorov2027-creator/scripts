#!/bin/bash
echo "select the operation ************"
echo "  1)operation 1"
echo "  2)operation 2"
echo "  3)operation 3"
echo "  4)operation 4" <br/>
read n
case $n in
  1) echo "You chose Option 1";;
  2) echo "You chose Option 2";;
  3) echo "You chose Option 3";;
  4) echo "You chose Option 4";;
  *) echo "invalid option";;
esac
