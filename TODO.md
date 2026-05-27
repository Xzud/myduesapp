
AGENT NOTE: DO NOT CHANGE ANY INFORMATION OR WORDS HERE YOU CAN ONLY ADD [X] on completed tasks.

TODO: 

- [X] Add a "Delete all data" button with functionality, which clears all data for a fresh start. Must have a proper warning popup for this will delete the all user related data.
- [X] In Create loan add an option to toggle from Principal Amount to Monthly Amount to pay, this is for payments that the user knows the monthly amount but not the total amount.
- [ ] In Create due add "Include Interest" either in percentage, monthly fixed amount or total interest amount that will be divided per month.


App Logic:
- [ ] Create the app logic for All Dues, with editting an deleting the due itself inside its own due overview.

- [ ] Allow Single or Multiple Billing Period Selection for Due Population: Create the logic in Create due to select single or multiple on which billing period does the due populate e.g. if chosen day 7 then loan will only be populated in the 7th of each month and if the 2 billing dates are chosen then it will populate on each like how it is currently.

Frontend:

- [X] Create another tab called "All Dues" this is a Due specific tab where it lists all dues in total amount how many months to pay and how many have already been paid if clicked or tapped you will go to its own overview page where it has the full details of the Due and the list of how monthly segmentation. The completed will have a green border top color while others to pay have gray border-top color.
- [ ] Allow Single or Multiple Billing Period Selection for Due Population: Create the ui and the presentation part




Not fully implemented:

  - The All Dues page is currently a showcase backed by _mockDues, not the real
    app logic. See lib/features/dues/presentation/pages/
    all_dues_showcase.dart:24 and lib/features/dues/presentation/pages/
    all_dues_showcase.dart:506.
  - I did not find real edit/delete-due app logic in the overview flow.
  - Include Interest is not implemented yet.

  If you want, I can turn this into a cleaned-up checklist showing:

  1. already implemented,
  2. partially implemented,
  3. still missing.

