# MediaOrganizer
If you want to consolidate all the picutres and vidoes you have taken over years that are spread across many old hard drives you can use this script to consolidate and organize them by Year/ Month etc.
 
Steps to use the script are 

1) Put this script in an external hard drive. This will also be the place where you will consolidate your pictures and videos. Make sure that the drive is fast enough and has enough free disk space.
2) run the Import.cmd file.
3) Select the folder you want to import.

The script will scan the folder for .jpg, .mov,.jpeg,.bmp,.mp4,.avi,.wav,.mpg,.3gp and extract Time picture was taken, GPS info, Make and Model of the camera and generate a file hash.

Then it imports the data into the  ./ManagedMedia folder where it will Oraganize the pictures by {YEAR}\{MONTH}\{MAKE}\{FOLDER} and ensure that there are no duplicates in ./ManagedMedia

You can run the script for each of your sources and over time have a clean organized photo colleaction.

The folder organization can be any updated to suite your taste. Variables available MAKE,MODEL,YEAR,MONTH. I intend to add COUNTRY, STATE and CITY at some point and I am looking for a free geocoding service for this. google service requires an API key. 

If you know of any free geocoding service please let me know.

Default folder organization is {YEAR}\{MONTH}\{FOLDER} and can be overridden by creating a setting.xml in the root folder.
example : <Setting OrganizeBy="{YEAR}\{MONTH}\{FOLDER}" ></Setting>


Please note that metadata generated is saved in /ManagedMedia/ManagedMedia.csv . Please dont delete this file as this is used for de duplication. Also dont add or change files manually under /ManagedMedia  and you should consider them as read only copy organized and managed by this script.

if after importing the data you decide to reorganize the folder structure update the setting xml and run ReorgMedia.cmd

Thank you!



