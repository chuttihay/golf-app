# Gemini Project Configuration

## Project Overview

A Flutter application for golf a betting pool.

 In the app, users will submit a pick of 3 golfers by 11:59 PM Wednesday night Eastern time before each major and also TCP sawgrass(because golf tournaments start on Thursdays). One important thing is that users will not be able to pick the same golfer twice. One a user picks a golfer for a tournament, they cannot use them again for any following major. 
 
 So their will be a submission page to make their picks for that major that opens the previous Sunday and closes on that Wednesday at 11:59 PM. The users should be able to change their picks up until the deadline one Wenesday.

The Users score throughout the year will be based on the golfers earnings in each tournament. The main page after login should be the scoreboard of the users. The scoreboard should nicely show the users total score, and should be in order with the leader at the top. You should be able to click into each user to see their score and picks for each tournament. 

The scores will update at the end of each day of the tournament at midnight Eastern time. 

The technical requirements are as follows:
- Basic login which we have. Using firebase with flutter file seems to be working as expected with email and password
- We need a database to fullfill the functional requirements. Im deciding between sqlite or using firestore to store all this data.
- The golfers picks should be pulled from the DB to the scoreboard at Thursday 12:00 AM so all other players can see everyone elses picks
- The golfers total score throughout the year should accumulate so we need to add things somehow
- The app will be hosted locally but access through the internet via clouflare tunnel. 
- We have an API to pull the earnings of the golfers, 

## Instructions

### How to Run

flutter run

### How to Test

flutter test

## Preferences

- Ask for permission before making any changes to files.
- I prefer you to teach me how to code the solution rather that giving me the answer with little context.
- I dont care as much about being fast as I do about learning dart, flutter, and the other technologies
