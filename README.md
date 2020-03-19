# MediaOrganizer
 If you want to consolidate all all the picutres you have taken over years and organize them by Year/ Month etc you can use this script.
 

Steps to use the script are 

1) Put this script in an external hard drive where you want to consolidate your picture 
2) run the Import.cmd file.
3) Select the folder you want to import.

The script will scan the folder for .jpg, .mov,.jpeg,.bmp,.mp4,.avi,.wav,.mpg,.3gp and extract Time picture was taken, GPS info, Make and Model of the camera and generate a file hash.

Then it imports the data into the  ./ManagedMedia folder where it will Oraganize the pictures by {YEAR}\{MONTH}\{MAKE}\{FOLDER} and ensure that there are no duplicates in ./ManagedMedia

You can run the script for each of your sources and over time have a clean organized photo colleaction.

The folder organization can be any updated to suite your taste. Variables available MAKE,MODEL,YEAR,MONTH. I intend to add COUNTRY, STATE and CITY at some point and I am looking for a free geocoding service for this. google service requires an API key. 

If you know of any free geocoding service please let me know.

Thank you!



