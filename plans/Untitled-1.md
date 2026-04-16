We need a sync button at the top of the app to sync quickly/easily

we have several layers of audits post refactor and post large implementations, as well as pre production and code hygiene audits done. We're trying to confirm these audits and brainstorm specs and create implementation plans to get our codebase to 100 clean and functional code. Use Opus level agents to explore and gather context. We are looking to use the brainstorming skill to create a spec for the audit in an attempt to get closer to production/beta. We will /tailor the spec and then use the writing plans skill on it. Please analyze the attached audit, then review codebase's layer that matches the audit and verify the errors that were found.  

New documentation system idea - 

Need to start documenting through github commits much more
 - standardize commit structure to tell a story
 - organize commits per our 8 layer structure
 - try to commit the phase if implementing a plan
 - create a phase map in a plan so when commit phases agents dont read the entire plan
 - 

  CLAUDE - 


  ❯ Do NOT stop iterating until the specs intent has been fully and completely captured. Do not forget that we do not want any god class screens, widgets, methods, helpers, over 300 lines. We want all UI screen API  endpoints to be easily exposed for the sync engine coordinators and orchestrators.This has been a major pain point and it has made it hard to verify our sync system. Confirm that all lint rules have been applied and are fixed and that no ignore rules or  other AI tricks have been applied to mitigate following the lint rules.

  Please add to or update your TODO list with these new requirements. 

  DO NOT STOP until you have finished and the specs intent has been fully captured.  


  › Yes let's install docker and figure out how to get the remote work accessible to you unless you've already figured it out                 
                                                                                                                                            

• Run these from an elevated PowerShell.
                                                                                                                                            
  Docker / Local Supabase                                                                                                                   
                                                                                                                                            
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart                                      
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart                                                 
                                                                                                                                            
  wsl --update                                                                                                                              
                                                                                                                                            
  winget install --id Docker.DockerDesktop --exact --accept-package-agreements --accept-source-agreements                                   
                                                                                                                                            
  Restart-Computer                                                                                                                          
                                                                                                                                            
  & "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

  Then verify:
  docker info
  supabase --version
  cd C:\Users\rseba\Projects\Field_Guide_App
  supabase status
  supabase start

  If docker version and supabase start work, I’ll be able to run the local Supabase stack, reset/apply migrations, and validate the DB side 
  of the beta work from this repo.

  Remote Supabase
  Remote access is already working from this shell. I already confirmed:

  supabase projects list

  and it returned your linked project Construction Inspector App with ref vsqvkxvvmnnhdajtgblj.

  If you want to re-link explicitly from admin PowerShell anyway:


  supabase login

  Once Docker is running, tell me the results of:


  and I’ll continue with local-stack validation plus the refactor work.

───────────────────────────────────────────────────────────────────────────
Please turn these testing notes into a comprehensive spec. I'm going to go to bed for the night and I'd like you to create a TODO out of all of these items and keep iterating until all of them are completed. 

Testing notes - 

  - When deleting a project there is no-auto refresh, this needs to be fixed, make sure this doesn't happen in other areas of the app as well. 
  - When editing the activities, when you click done, it doesn't show the data you've typed out, this must be fixed
  - When creating equipment in the create equipment popup there the equipment is listed and scrollable, this is fine but you can only see one piece of equipment at a time and its extremely unclear you can scroll. Needs to be fixed, the user would never know to scroll to find the equipment to delete/edit
  - When editing an entry by clicking continue todays entry in the dashboard, it says new entry. I know we use the new entry screen but can we make this a bit more honest / user friendly
  - If I submit the entry for the day I was working on and I click continue todays entry from the dashboard it starts a new entry. It should ask if you'd like to unsubmit as there is already an entry for this day
  - We need to have a way to intuitively make a report for a different date, I think the best way to do this is to allow the user to edit the date of a report in the new entry wizard
  - entries can be backdated by selecting a calendar day prior in the calendar screen, this is good. 
  - the calendar screen has an overflow error, this tells me that this hasn't been properly tokenized/scaffolded as the sizing should be adaptive. Our responsive scaffolding should've handled this I believe
  - There are no forms in the Forms screen in the Toolbox, when clicking the + icon it brings up a scroll box on the bottom of the screen that stays down and you can't do anything with it
  - When loading into another project and on a different user/user role that another account is on, it shows their trash as mine, it just had 390 items in my  trash can on a different account
  - The double screen view for the windows version of the dashboard just shows two of the same screen, this is pointless. Better to just keep this screen as one for now until we redesign it better
  
 Forms -  
  - The station selection in the quick test section doesn't display a + sign, we display stations as xx+xx so we need to have a + 
  - The items of work are wrong, there is a table on the 0582B at on the second page of the pdf that displays the different items of work, we want the actual item names in the app and then the exported item of work is the item corresponding item code, we need to have a way to display the Density Requirements 
  -  when its the 'original' test we just want want it to be numbered chronologically, this should go in descending order per test, except when recheck has been checked, we display a recheck number subsequent to the original until the inspector gets a passing test, and then we continue back with the chronological numbering
  - It blocks me from exporting a 0582B without required fields, it shouldn't do this, we can always edit the form after its exported as well. forms aren't to be flattened on export
  - We only need to display to .0 accuracy on the 0582B. We are currently displaying as .00, this needs to be fixed.
  - After saving the 0582B it doesn't display in the 'saved responses' section of the 0582B tab in the forms gallery
  - When bringing the app to foreground after you've hit the home button the app loads in very slow, and also doesn't seem to assume state ownership because when i hit the back key it closes the app, this essentially locks the app until its killed and even then restarts to the same screen, so locks the user out of the app. When the app is completely closed and not just backgrounded you should be brought to the projects selection page if auth isn't needed. This is very important to get right, I'm thinking this could possibly be because we don't have proper nested screen routes but I'm not sure, this happens app wide too
  - Export didn't work, brought up multiple bottom screens, didn't let me select a file path for export, The other options are fine but need to be able to export to a dated folder. Should also prompt to ask if I'd like to attach this to a form or export as is
  





Lint Rules - 

  - One state-ownership rule per screen: detail screens render the live provider/model source, not stale screen-local copies after mutation.
  - One mutation contract: every create/update/delete must either update the canonical provider state or trigger a required reload path immediately.
  - One route-intent layer: actions like continue today, new entry, view submitted, edit draft should go through shared intent helpers, not screen-local ad hoc navigation.
  - One preload contract for screens/sheets: if a screen depends on builtin forms, contractor data, etc., it must load that before interactive controls enable.
  - One responsive content contract for dialogs/sheets: scrolling regions get explicit constraints and visible affordances, not “Flexible inside whatever dialog happens to host it”.
  - Contract tests for those behaviors: not just widget snapshots, but tests that assert “save updates visible state”, “delete removes item without manual refresh”, “continue today reopens today’s entry”, and “sheet never opens empty when action is enabled”.


Testing Notes - 

  - 0582B isn't writing to the preview, I click send to form after filling out the header, weights, and testing sections and then click pdf preview and it shows no data. You confirmed you fully verified all the mappings on the device as well as the exported forms, it appears this was never actually done or not completed.
  - 0582B has no way to enter in the density and moisture value ranges as well as the density and moisture reading. We need to fix this.
  - We need to create a navigation bar equivalant to phones/tablets because currently there are several screens you can get 'stuck' on.
  - Our PDF preview needs to have a pan and zoom.
  - There is data being entered into the remarks section for some reason in the 0582B
  - Columns F, G, H aren't being autofilled like they usually are, if you view the original form by itself, and enter in data it will auto fill those 3 columns from entered in data from previous columns
  - Need to match the original formatting of the form in the entered text fields, all your data is being entered into a flattened form,  the form fields must be preserved. (the text is sitting on the left edge of every column, but when entering text into the actual pdf, text sits centered in the cells, this is an issue on ALL of our forms)
  - The connected samsung device is still having trouble recovering after a bad sync/resuming from a background state, its acting like the connectivity is broken. Take a screenshot.
  - please review all of these items, add them to a todo list, and fully verify all fixes/tests/verification is green before reporting back







  - When on the inspector role and no project is selected, there is a create project button in the calendar tab, this shouldn't be there, inspectors cant create projects. (Re check)


  - We need to create a new role; Office Technician, this person can also assign inspectors to projects and create projects. They review inspectors entries and can leave comments on their work via a comment system. Engineers can do the same. We will need a place for the comments to land, I was thinking a tab in the TODO's for the inspector that the comments land in, so they can check these and see them and make appends to any of the things found wrong. the inspector could get a small notification card in the dashboard when there is a new review comment in TODOs
  - when attaching a photo you should be able to click on the name and edit the name after its been attached
  - On the daily entrie wizard contractor card, when adding personnel types I want the scroll list to be the same as the contained scroll list when adding equipment types
  - For the HMA calculator I want this to say HMA Yield Calculator; I want the density portion removed from this. It's assumed HMA is 110 lb per sq/yd per 1 inch depth. 2 inches thick is 220 lb per sq/yard ect. The calculator should allow you to input width and lengths for varying road widths.
  - We need a second calculation for HMA; a weighback calculator. This will used an assumed yield (from the last calculated yield) or it can be manually entered, we will use this and the length/width left to finish and give an estimated yield.
  - The concrete calculator doesn't need to say concrete calculator, it just needs to say Calculator, it should be an interactive calculator for calculating area. it should have ways to switch from cft/cyd, syd/sft.

Pay App Fixes - 

- When trying to create a new pay app, it doesn't allow us to overwrite. It lets us select the option to do so, but it doesn't actually begin the overwriting process. We don't need to overwrite the previous pay app; we need a way to export the previous pay apps we've already done, preserving their state while maintaining our current state. We also need to add a little more detail to the analytics page. Currently there is no way to view progress by item in a nicer list view, nor to view the pay applications one at a time. The project summary isn't very easy to see; it's a bit dense. Our top priority is getting the pay app to properly export to any state of the previous pay app. We need to be able to export copies of the previous pay apps and obviously keep appending the current one. Because this is a resource‑heavy thing, we should try to at least hang on to the previous pay app so we're not generating a new one for every subsequent pay app, if that makes sense. Please ask me any questions you need to make my intent unambiguous, but we really need to get this payapp thing verified end‑to‑end as fast as possible.

Tablet layout fixes - 

  - In the daily entry wizard on the tablet view of our app, the activities card should be on the left-hand side beneath the header card. This creates a larger section, allowing the full report to be seen at once in the read‑only view. It would clean up the look and make better use of the space.
  - The quantity calculator should be wired to the toolbox calculator that calculates all the different shapes and square footages. We should be able to reuse that. I would like you to redo all of the calculator buttons to look a little bit nicer. I don't like the orange look; it doesn't fit with the rest of the app, and I'm not sure about the way the buttons look either.
  - In the tablet view of our app, when we are in the Pay Items and Quantities tab on the right-hand side, clicking a pay item does not update to the next pay item. It only brings up the bottom scroll card, which updates to the selected pay item but not the right-hand side. In tablet view we do not want this bottom scroll card to pop up because the information is already displayed on the right-hand side, but we do want it to appear in the phone view.
  - The projects view doesn't need to be a split screen. I don't think there's any utility in this; it's just wasting space. This is in our tablet view.
  - Is there any logic we can add to our app to detect when a pen is being used on a tablet to write on the surface, so we can have palm detection and make writing easier? Or would that be too hard to tune quickly? 



Testing Notes - 

- ALL user flows MUST be tested e2e forwards and backwards through UI navigation. There is a serious problem with how we handle UI navigation, its not standardized and it seems like we get into nested screens alot that can't be traversed backwards easily. This needs to be optimized on the phone, tablet, and Windows builds. We have to make sure that the UI navigation makes sense throughout all of the user flows. We need to devise some kind of a testing flow, broken down by feature, that tests all of the UI. We already have a separate sync flow, but we need something that just verifies the UI flows and the nested screens and the ability to navigate forwards and backwards through each screen on each type of device, like the phones or tablets or Windows. We need to add to our current end-to-end flows, but we need to redesign them with our new UI system in mind while also optimizing and breaking down our UI with our testing in mind. Making sure that everything is completely testable in our flows, that way we can be a little bit more sure and deterministic in our testing and our building. 

- All user account roles must be hardened in our sync system. Perform a full e2e audit of each user role on our sync and authentication system. These two systems need to along with the UI need to be seemlessly aligned. We've added a few more accounts to the database and created a few more projects, and metadata is being seen all over the place and having flashing effects. That tells me our state management is very poor. We need to devise a way to test our different roles and authentication extremely thoroughly and tighten everything significantly, in a lot more depth than we currently have. I don't know if we need to use our docker CLI, different docker containers, to fully test all of the different roles in a more in depth way, but we need a better way to harden all of the different roles on Supabase and SQLite. We have people testing the app now so I don't want to make the best practice testing and iterating on the live supabase database anymore, I'm not sure what should be done to standardize this, I was thinking the docker containers. It seems like were having alot of bleed through when creating new projects, if users have already been assigned a project and a new project was created it is flashing meta data of the new project to users. Were having trouble with new users being assigned to older projects. Were having issues with projects being downloaded. Were potentially having issues when multiple accounts with differing roles are signed into the same device. We need a complete and thorough e2e audit of the auth system, all screens, user roles and all of their permissions, and their user flows through the entire app e2e. This is of utmost important. We need to test data flows in all directions. But what is the best, most insightful, resourceful, bug-finding, way for us to build and iterative testing system that tests our sync system integrity and strength going forward, with benchmarks. Sometimes, when refreshing, I can see projects that I shouldn't. They pop up for a second and then disappear. This can be very confusing to inspectors that don't understand what's going on. They shouldn't be able to see other projects. This is part of our role hardening we need to do. 

- We need to set up the equivalent CI/CD for Android. We've already set up Codemagic and App Connect. I'm going to need you to help me walk through the Android equivalent to that. We want to use Codemagic as our comprehensive and singular CI/CD pipeline, but we want it to be a little bit more controlled and run through GitHub. That way we're not always pushing to the new builds, and we can decide when we want to push to the new ones. I know we're going to have to include Firebase to be able to push out updates, because we want the Android equivalent of TestFlight as well. It makes it extremely easy to push builds out to testers, etc. 


