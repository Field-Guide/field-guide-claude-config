# Form Entry Flow Wireframe Mockups

## Primary Layout Decision

S21 portrait is a two-column data-entry surface for quick fields. The redesign
must not waste half the screen by stacking short fields one per row.

Use full-width fields only for actual long-form text or signature surfaces:

- 1174R Remarks / computations
- 1174R QA Comments
- 1126 Remarks
- 1126 Corrective action when it is a sentence-level note
- Pressure Test Report Remarks
- Signature capture/confirmation surfaces

Everything else should be designed as compact two-column entry on S21 and as
two-column or wider table/grid entry on tablet landscape.

## Reading Key

```text
[value........]         Editable field
[Button]               Button
v / ^                  Collapsed / expanded section
>>                     Active edit row
```

## Shared Flow Shape

The screen should feel like a compact workflow, not a long form dump.

Repeated printed-row sections use one active app-entry composer at a time. The
composer writes to the next available printed PDF row. Existing rows appear as a
compact editable mini table, and selecting a row turns that same composer into
an edit surface for that row. The app should not show every printed row as a
separate duplicate input group.

When the mini table has filled every printed row available on the PDF, the add
composer is hidden and the section shows `printed rows are full`. Existing rows
remain editable from the mini table.

```text
S21 portrait
+------------------------------------------------+
| < 1174R Concrete                    [eye] [up] |
+------------------------------------------------+
| Progress 3 of 7                                |
| [Header] [Place] [Air] [QA] [Qty] [More]       |
+------------------------------------------------+
| A Header                                    v  |
| Contractor Ajax - Route M-43                  |
+------------------------------------------------+
| B Placement                                 v  |
| Air 5-8 - Slump 2-4 - Water 2                 |
+------------------------------------------------+
| C Air / Slump                               ^  |
| 2 observation rows started                    |
| << active two-column entry surface >>         |
+------------------------------------------------+
| D QA                                        v  |
| 1 QA row - Lot 1 / Random 42                  |
+------------------------------------------------+
| E Quantities                                v  |
| 1 row - Item 706002                           |
+------------------------------------------------+
```

```text
Tablet landscape
+------------------------------+---------------------------------------------------+
| Workflow rail                | Active and collapsed sections                    |
| Progress 3 of 7              |                                                   |
| >> A Header       Complete   | C Air / Slump                               ^    |
| >> B Placement    Complete   | << active wide entry surface >>                  |
| >> C Air          Editing    |                                                   |
|    D QA           Started    | D QA                                        v    |
|    E Quantities   Started    | 1 QA row - Lot 1 / Random 42                     |
|    F Remarks      Started    |                                                   |
|    G Closeout     Pending    | E Quantities                                v    |
+------------------------------+---------------------------------------------------+
```

# MDOT 1174R

## 1174R Header

Field order stays row-major:

1. Contractor
2. General name of project
3. Subcontractor
4. Control section ID - job number
5. Concrete supplier
6. Route
7. Report number
8. Date

### S21 Portrait

```text
+------------------------------------------------+
| A Header                                    ^  |
| Contractor Ajax - Route M-43                  |
+-----------------------+------------------------+
| Contractor            | General name of project|
| [Ajax Paving......]   | [M-43 Bridge.......]   |
+-----------------------+------------------------+
| Subcontractor         | Control section ID -   |
| [................]    | job number             |
|                       | [39031-204581.....]    |
+-----------------------+------------------------+
| Concrete supplier     | Route                  |
| [Consumers........]   | [M-43.............]    |
+-----------------------+------------------------+
| Report number         | Date                   |
| [001.............]    | [2026-05-11.......]    |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| A Header                                                                      ^  |
+----------------------+----------------------+----------------------+-------------+
| Contractor           | General name project | Subcontractor        | CS/job      |
| [Ajax Paving......]  | [M-43 Bridge.....]   | [................]   | [39031...]  |
+----------------------+----------------------+----------------------+-------------+
| Concrete supplier    | Route                | Report number        | Date        |
| [Consumers........]  | [M-43............]   | [001............]    | [2026...]   |
+----------------------+----------------------+----------------------+-------------+
```

## 1174R Placement / Water / Curing / Target Ranges

Field order stays row-major:

1. Maximum time
2. Structure number
3. Weather A.M.
4. Weather P.M.
5. Max. water added per CYD
6. Reason
7. Beams/cylinders made
8. Curing compound used gallons
9. Intended air min %
10. Intended air max %
11. Intended slump min
12. Intended slump max

### S21 Portrait

```text
+------------------------------------------------+
| B Water, Beams, Curing & Target Ranges      ^ |
| Air 5-8 - Slump 2-4 - Water 2                 |
+-----------------------+------------------------+
| Maximum time          | Structure number       |
| [90 min..........]    | [S03..............]    |
+-----------------------+------------------------+
| Weather A.M.          | Weather P.M.           |
| [Cloudy 58F......]    | [Part cloudy 66F..]    |
+-----------------------+------------------------+
| Max. water added      | Reason                 |
| per CYD               | [Adjust slump.....]    |
| [2...............]    |                        |
+-----------------------+------------------------+
| Beams/cylinders made  | Curing compound used   |
| [4 cylinders.....]    | gallons                |
|                       | [1.5..............]    |
+-----------------------+------------------------+
| Intended air min %    | Intended air max %     |
| [5...............]    | [8................]    |
+-----------------------+------------------------+
| Intended slump min    | Intended slump max     |
| [2...............]    | [4................]    |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| B Water, Beams, Curing & Target Ranges                                        ^  |
+----------------------+----------------------+----------------------+-------------+
| Maximum time         | Structure number     | Weather A.M.         | Weather P.M.|
| [90 min..........]   | [S03.............]   | [Cloudy 58F......]   | [Partly...] |
+----------------------+----------------------+----------------------+-------------+
| Max. water / CYD     | Reason               | Beams/cyl made       | Curing gal. |
| [2...............]   | [Adjust slump....]   | [4 cylinders.....]   | [1.5.....]  |
+----------------------+----------------------+----------------------+-------------+
| Intended air min %   | Intended air max %   | Intended slump min   | Slump max   |
| [5...............]   | [8...............]   | [2...............]   | [4.......]  |
+----------------------+----------------------+----------------------+-------------+
```

## 1174R Air / Slump

This section should be the clearest example of S21 using two columns. Left and
right observations sit side by side.

Field order per printed row:

1. Left Time
2. Left Atmosphere
3. Left Concrete
4. Left Air content %
5. Left Slump
6. Left Cylinders / beams
7. Right Time
8. Right Atmosphere
9. Right Concrete
10. Right Air content %
11. Right Slump
12. Right Cylinders / beams

### S21 Portrait - Scan Mode

```text
+------------------------------------------------+
| C Temperatures - Air - Slump                ^ |
| 2 observation rows started                    |
+------------------------------------------------+
| Printed rows                                  |
| Row | Left summary        | Right summary      |
| 1   | 9:15 / 6.2 / 3.0    | 9:20 / 6.1 / 3.0  |
|     | [Edit row 1]                              |
| 2   | 10:40 / 6.0 / 3.5   | 10:45 / 6.0 / 3.5 |
|     | [Edit row 2]                              |
+------------------------------------------------+
| Next row entry                                |
+-----------------------+------------------------+
| Left observation      | Right observation      |
+-----------------------+------------------------+
| Time                  | Time                   |
| [................]    | [................]     |
+-----------------------+------------------------+
| Atmosphere            | Atmosphere             |
| [................]    | [................]     |
+-----------------------+------------------------+
| Concrete              | Concrete               |
| [................]    | [................]     |
+-----------------------+------------------------+
| Air content %         | Air content %          |
| [................]    | [................]     |
+-----------------------+------------------------+
| Slump                 | Slump                  |
| [................]    | [................]     |
+-----------------------+------------------------+
| Cylinders / beams     | Cylinders / beams      |
| [................]    | [................]     |
+-----------------------+------------------------+
| [Add observation row]                         |
+------------------------------------------------+
```

### S21 Portrait - Editing Printed Row

```text
+------------------------------------------------+
| C Temperatures - Air - Slump                ^ |
| Editing printed row 1                         |
+------------------------------------------------+
| Printed rows                                  |
| >> 1 | 9:15 / 6.2 / 3.0 | 9:20 / 6.1 / 3.0   |
|    2 | 10:40 / 6.0 / 3.5| 10:45 / 6.0 / 3.5  |
+------------------------------------------------+
| Edit printed row 1                            |
+-----------------------+------------------------+
| Left observation      | Right observation      |
+-----------------------+------------------------+
| Time                  | Time                   |
| [9:15............]    | [9:20............]     |
| Atmosphere            | Atmosphere             |
| [58..............]    | [60..............]     |
| Concrete              | Concrete               |
| [67..............]    | [68..............]     |
| Air content %         | Air content %          |
| [6.2.............]    | [6.1.............]     |
| Slump                 | Slump                  |
| [3.0.............]    | [3.0.............]     |
| Cylinders / beams     | Cylinders / beams      |
| [2 cyl...........]    | [2 cyl...........]     |
+-----------------------+------------------------+
| [Save printed row 1]            [Cancel]       |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| C Temperatures - Air - Slump                                                  ^  |
+----------------------------------------------------------------------------------+
| Printed rows                                                                     |
| Row | L time | L atm | L conc | L air | L slump | R time | R atm | R conc | R air |
| 1   | 9:15   | 58    | 67     | 6.2   | 3.0     | 9:20   | 60    | 68     | 6.1   | [Edit]
+-----------------------------------------+----------------------------------------+
| Left observation                         | Right observation                      |
| Time              [................]     | Time              [................]   |
| Atmosphere        [................]     | Atmosphere        [................]   |
| Concrete          [................]     | Concrete          [................]   |
| Air content %     [................]     | Air content %     [................]   |
| Slump             [................]     | Slump             [................]   |
| Cylinders / beams [................]     | Cylinders / beams [................]   |
+-----------------------------------------+----------------------------------------+
| [Add observation row]                                                             |
+----------------------------------------------------------------------------------+
```

## 1174R QA Cylinder Table

Field order per row:

1. Lot #
2. Lot size
3. Sublot #
4. Sublot size
5. Random #
6. QA cylinder
7. ID
8. Discrepancy
9. Cylinder

User-facing comments field:

1. Comments

PDF/storage implementation detail:

1. comments
2. comments_continued

### S21 Portrait

```text
+------------------------------------------------+
| D QA Cylinder Table                         ^ |
| 1 QA row - Lot 1 / Random 42                  |
+------------------------------------------------+
| Printed rows                                  |
| Row | Lot/Sublot | Random | QA cyl | ID        |
| 1   | 1 / A       | 42     | Yes    | QA-1      |
|     | [Edit row 1]                              |
+------------------------------------------------+
| Next row entry                                |
+-----------------------+------------------------+
| Lot #                 | Lot size               |
| [................]    | [................]     |
+-----------------------+------------------------+
| Sublot #              | Sublot size            |
| [................]    | [................]     |
+-----------------------+------------------------+
| Random #              | QA cylinder            |
| [................]    | [................]     |
+-----------------------+------------------------+
| ID                    | Discrepancy            |
| [................]    | [................]     |
+-----------------------+------------------------+
| Cylinder              |                        |
| [................]    |                        |
+-----------------------+------------------------+
| Comments                                       |
| [............................................] |
| [Add QA row]                                  |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| D QA Cylinder Table                                                           ^  |
+----------------------------------------------------------------------------------+
| Row | Lot # | Lot size | Sublot # | Sublot size | Random # | QA cylinder | ID | Edit
| 1   | 1     | 500 CYD  | A        | 100 CYD     | 42       | Yes         | QA-1 | [Edit]
+----------------------+----------------------+----------------------+-------------+
| Lot #                | Lot size             | Sublot #             | Sublot size |
| [................]   | [................]   | [................]   | [.........] |
| Random #             | QA cylinder          | ID                   | Discrepancy |
| [................]   | [................]   | [................]   | [.........] |
| Cylinder             |                      |                      |             |
| [................]   |                      |                      |             |
+----------------------+----------------------+----------------------+-------------+
| Comments                                                                          |
| [..............................................................................]  |
+----------------------------------------------------------------------------------+
```

QA comment behavior:

- The user sees one Comments field.
- If the text is long enough to require the second printed PDF line, the app
  splits it behind the scenes.
- When reopening older saved forms, the app hydrates the one Comments field
  from `comments` plus `comments_continued`.

## 1174R Quantities

Field order per row:

1. Item or code no.
2. Sta. to Sta.
3. Grade of conc.
4. Length
5. Width
6. Depth
7. Measured sq/cu yards
8. CYDS. plan
9. CYDS. used
10. CYDS. waste
11. Over / under %

### S21 Portrait

```text
+------------------------------------------------+
| E Item / Quantity Table                     ^ |
| 1 row - Item 706002                           |
+------------------------------------------------+
| Printed rows                                  |
| Row | Item/code | Sta. to Sta. | Used | Edit   |
| 1   | 706002    | 12+00-14+50  | 18.5 | [Edit] |
+------------------------------------------------+
| Next row entry                                |
+-----------------------+------------------------+
| Item or code no.      | Sta. to Sta.           |
| [................]    | [................]     |
+-----------------------+------------------------+
| Grade of conc.        | Length                 |
| [................]    | [................]     |
+-----------------------+------------------------+
| Width                 | Depth                  |
| [................]    | [................]     |
+-----------------------+------------------------+
| Measured sq/cu yards  | CYDS. plan             |
| [................]    | [................]     |
+-----------------------+------------------------+
| CYDS. used            | CYDS. waste            |
| [................]    | [................]     |
+-----------------------+------------------------+
| Over / under %        |                        |
| [................]    |                        |
+-----------------------+------------------------+
| [Add quantity row]                            |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| E Item / Quantity Table                                                       ^  |
+----------------------------------------------------------------------------------+
| Row | Item/code | Sta. to Sta. | Grade | L | W | D | Measured | Plan | Used | Edit
| 1   | 706002    | 12+00-14+50  | P1    |   |   |   | 18.5     | 20   | 18.5 | [Edit]
+----------------------+----------------------+----------------------+-------------+
| Item or code no.     | Sta. to Sta.         | Grade of conc.       | Length      |
| [................]   | [................]   | [................]   | [.........] |
| Width                | Depth                | Measured sq/cu yards | CYDS. plan  |
| [................]   | [................]   | [................]   | [.........] |
| CYDS. used           | CYDS. waste          | Over / under %       |             |
| [................]   | [................]   | [................]   |             |
+----------------------+----------------------+----------------------+-------------+
```

## 1174R Remarks / Computations

This is one of the few full-width exceptions because the user is composing a
note, not entering a precise value.

### S21 Portrait

```text
+------------------------------------------------+
| F Remarks / Computations                    ^ |
| Pour delayed 20 minutes                       |
+------------------------------------------------+
| Remarks / computations                        |
| +--------------------------------------------+ |
| | Pour delayed 20 minutes while truck        | |
| | adjusted slump. Lot 1 accepted.            | |
| |                                            | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| F Remarks / Computations                                                      ^  |
+----------------------------------------------------------------------------------+
| Remarks / computations                                                           |
| +------------------------------------------------------------------------------+ |
| | Pour delayed 20 minutes while truck adjusted slump. Lot 1 accepted.           | |
| |                                                                              | |
| +------------------------------------------------------------------------------+ |
+----------------------------------------------------------------------------------+
```

## 1174R Closeout

Field order:

1. Mix or street technician
2. Date
3. Prepared by
4. Checked by
5. Closeout date

### S21 Portrait

```text
+------------------------------------------------+
| G Closeout                                  ^ |
| Prepared by pending                           |
+-----------------------+------------------------+
| Mix or street         | Date                   |
| technician            | [................]     |
| [................]    |                        |
+-----------------------+------------------------+
| Prepared by           | Checked by             |
| [................]    | [................]     |
+-----------------------+------------------------+
| Closeout date         |                        |
| [................]    |                        |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| G Closeout                                                                    ^  |
+----------------------+----------------------+----------------------+-------------+
| Mix/street technician | Date                 | Prepared by          | Checked by  |
| [................]   | [................]   | [................]   | [.........] |
| Closeout date        |                      |                      |             |
| [................]   |                      |                      |             |
+----------------------+----------------------+----------------------+-------------+
```

# MDOT 1126 Weekly SESC

## 1126 Header

Field order:

1. Control section
2. Job number
3. Contractor name
4. Inspector name
5. Route
6. Construction engineer / maintenance coordinator
7. Storm water operator number
8. Comprehensive training number

### S21 Portrait

```text
+------------------------------------------------+
| A Header                                    ^  |
| CS 39031 - Inspector Maria Lopez              |
+-----------------------+------------------------+
| Control section       | Job number             |
| [39031...........]    | [204581..........]     |
+-----------------------+------------------------+
| Contractor name       | Inspector name         |
| [Ajax Paving.....]    | [Maria Lopez.....]     |
+-----------------------+------------------------+
| Route                 | Construction engineer /|
| [M-43............]    | maintenance coordinator|
|                       | [Sam Patel.......]     |
+-----------------------+------------------------+
| Storm water operator  | Comprehensive training |
| number                | number                 |
| [SW-10042........]    | [CT-88931........]     |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| A Header                                                                      ^  |
+----------------------+----------------------+----------------------+-------------+
| Control section      | Job number           | Contractor name      | Inspector   |
| [39031............]  | [204581..........]   | [Ajax Paving.....]   | [Maria...]  |
| Route                | Construction eng.    | Storm water op no.   | Training no.|
| [M-43.............]  | [Sam Patel.......]   | [SW-10042........]   | [CT-88931] |
+----------------------+----------------------+----------------------+-------------+
```

## 1126 Inspection Dates & Precipitation

Field order:

1. Report number
2. Inspection date
3. Last precipitation resulting in discharge
4. Rainfall event Date
5. Rainfall event Inches
6. Date of last inspection

### S21 Portrait

```text
+------------------------------------------------+
| B Inspection Dates & Precipitation          ^ |
| Report 001 - 1 rainfall event                 |
+-----------------------+------------------------+
| Report number         | Inspection date        |
| [001.............]    | [2026-05-11......]     |
+-----------------------+------------------------+
| Last precipitation    | Date of last inspection|
| resulting in discharge| [2026-05-04......]     |
| [0.25 on 5/10....]    |                        |
+-----------------------+------------------------+
| Rainfall events                                |
| Row | Date          | Inches | Remove          |
| 1   | 2026-05-10    | 0.25   | [x]             |
+------------------------------------------------+
| Next rainfall event                            |
+-----------------------+------------------------+
| Date                  | Inches                 |
| [................]    | [................]     |
+-----------------------+------------------------+
| [Add rainfall event]                          |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| B Inspection Dates & Precipitation                                            ^  |
+----------------------+----------------------+----------------------+-------------+
| Report number        | Inspection date      | Last precipitation   | Last insp.  |
| [001..............]  | [2026-05-11......]   | [0.25 on 5/10....]   | [2026...]   |
+----------------------+----------------------+----------------------+-------------+
| Rainfall events                                                                  |
| Row | Date       | Inches | Remove                                                |
| 1   | 2026-05-10 | 0.25   | [x]                                                   |
| Date                 | Inches              | [Add rainfall event]                   |
| [................]   | [................]  |                                        |
+----------------------------------------------------------------------------------+
```

## 1126 Measures

Field order per measure:

1. Type of SESC measure / control
2. Location / station
3. Status: In place
4. Status: Needs action
5. Status: Removed
6. Corrective action, only for Needs action
7. Installation date, only for In place
8. Notification date, only for Needs action
9. Completion date, only for Removed

### S21 Portrait - Scan Mode

```text
+------------------------------------------------+
| C Type of Control / Location / Action       ^ |
| 3 measures - 1 needs action                    |
+------------------------------------------------+
| Measures                                       |
| Row | Measure / location      | Status         |
| 1   | Silt fence / Sta 12+50  | In place [Edit]|
| 2   | Inlet protect / CB-4    | Needs   [Edit] |
| 3   | Check dam / Ditch RT    | Removed [Edit] |
| [Add SESC measure]                             |
+------------------------------------------------+
```

### S21 Portrait - Editing Measure 2

```text
+------------------------------------------------+
| C Type of Control / Location / Action       ^ |
| Editing measure 2                              |
+------------------------------------------------+
| Measures                                       |
| 1 Silt fence / Sta 12+50       In place        |
| >> 2 Inlet protect / CB-4      Needs action    |
| 3 Check dam / Ditch RT         Removed         |
+-----------------------+------------------------+
| Type of SESC measure /| Location / station     |
| control               | [CB-4............]     |
| [Inlet protect...]    |                        |
+-----------------------+------------------------+
| Status                                         |
| [In place] [Needs action] [Removed]            |
+-----------------------+------------------------+
| Corrective action     | Notification date      |
| [Clean sediment...]   | [2026-05-11......]     |
+-----------------------+------------------------+
| [Save measure]                  [Cancel]       |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| C Type of Control / Location / Corrective Action                              ^  |
+----------------------------------------------------------------------------------+
| Row | Type/control      | Location/station | Status       | Date       | Edit      |
| 1   | Silt fence        | Sta 12+50        | In place     | 2026-05-01 | [Edit]    |
| 2   | Inlet protection  | CB-4             | Needs action | 2026-05-11 | [Edit]    |
+----------------------+----------------------+----------------------+-------------+
| Type/control         | Location/station     | Corrective action    | Notify date |
| [Inlet protection]   | [CB-4............]   | [Clean sediment...]  | [2026...]   |
| Status                                                                            |
| [In place] [Needs action] [Removed]                                               |
+----------------------------------------------------------------------------------+
```

## 1126 Remarks

Full-width exception because remarks are long-form notes.

### S21 Portrait

```text
+------------------------------------------------+
| D Remarks                                   ^  |
| No remarks entered yet                        |
+------------------------------------------------+
| Remarks                                       |
| +--------------------------------------------+ |
| |                                            | |
| |                                            | |
| |                                            | |
| +--------------------------------------------+ |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| D Remarks                                                                     ^  |
+----------------------------------------------------------------------------------+
| Remarks                                                                          |
| +------------------------------------------------------------------------------+ |
| |                                                                              | |
| |                                                                              | |
| +------------------------------------------------------------------------------+ |
+----------------------------------------------------------------------------------+
```

## 1126 Inspector Signature

Signature capture is a full-width exception on S21 because the control is not a
short data field.

### S21 Portrait

```text
+------------------------------------------------+
| E Inspector Signature                       ^ |
| Not signed                                     |
+-----------------------+------------------------+
| Typed signature       |                        |
| [Maria Lopez.....]    |                        |
+-----------------------+------------------------+
| Signature confirmation / preview               |
| +--------------------------------------------+ |
| |                                            | |
| +--------------------------------------------+ |
| [Sign]                                         |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| E Inspector Signature                                                          ^  |
+----------------------+-----------------------------------------------------------+
| Typed signature      | Signature confirmation / preview                          |
| [Maria Lopez.....]   | [signature surface]                                       |
|                      | [Sign]                                                    |
+----------------------+-----------------------------------------------------------+
```

# Water Main Pressure Test Report

## Pressure Test Report Source / Template Requirement

The source PDF is copied into the repo at:

```text
assets/templates/forms/water_main_pressure_test_report_source.pdf
```

That file is a visual/source reference only. It currently has an AcroForm
dictionary but zero AcroForm fields/widgets. The implementation must create a
new fillable template:

```text
assets/templates/forms/water_main_pressure_test_report_form.pdf
```

The final template must preserve the one-page visual layout and add semantic
AcroForm field names for every app-entered and app-calculated value.

## Pressure Test Daily Entry Attachment

The Pressure Test Report uses the same daily-entry attachment flow as the other
built-in forms. The form-entry screen starts after the user creates or opens the
form from the existing daily-entry form attachment workflow. There is no
Pressure-Test-specific attachment screen in this wireframe.

## Pressure Test Report Section Flow

```text
S21 portrait
+------------------------------------------------+
| < Pressure Test Report              [eye] [up] |
+------------------------------------------------+
| Progress 2 of 5                                |
| [Header] [Pipe] [Leakage] [Test] [More]        |
+------------------------------------------------+
| A Header                                    v  |
| Client / Project / Date                        |
+------------------------------------------------+
| B Pipe Section To Be Tested                 ^  |
| 150 psig - 2 hrs - 2 of 3 pipe rows            |
| << active two-column entry surface >>          |
+------------------------------------------------+
| C Allowable Leakage                         v  |
| 0.74 gal / 1 hr - 1.48 gal / 2 hrs             |
+------------------------------------------------+
| D Result Of Test                            v  |
| 2 result rows - loss pending                   |
+------------------------------------------------+
| E Remarks / Observer                        v  |
| Observer pending                               |
+------------------------------------------------+
```

```text
Tablet landscape
+------------------------------+---------------------------------------------------+
| Pressure Test Workflow       | B Pipe Section To Be Tested                  ^   |
| Progress 2 of 5              | << active wide entry surface >>                  |
| >> A Header       Complete   |                                                   |
| >> B Pipe         Editing    | C Allowable Leakage                         v   |
|    C Leakage      Calculated | 0.74 gal / 1 hr - 1.48 gal / 2 hrs             |
|    D Test         Started    |                                                   |
|    E Closeout     Pending    | D Result Of Test                            v   |
+------------------------------+---------------------------------------------------+
```

## Pressure Test Header

Field order:

1. Client
2. Date
3. Project Name
4. Project No.
5. Contractor
6. Description of Pipe Material
7. Manufacturer
8. Type of Joint

### S21 Portrait

```text
+------------------------------------------------+
| A Header                                    ^  |
| Client / Project / Date                        |
+-----------------------+------------------------+
| Client                | Date                   |
| [City of Paw Paw.]    | [2026-05-11......]     |
+-----------------------+------------------------+
| Project Name          | Project No.            |
| [Water Main Ext..]    | [WM-2026-04......]     |
+-----------------------+------------------------+
| Contractor            | Description of Pipe    |
| [Ajax Paving.....]    | Material               |
|                       | [DIP CL 52........]    |
+-----------------------+------------------------+
| Manufacturer          | Type of Joint          |
| [US Pipe.........]    | [Push-on..........]    |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| A Header                                                                      ^  |
+----------------------+----------------------+----------------------+-------------+
| Client               | Date                 | Project Name         | Project No. |
| [City of Paw Paw.]   | [2026-05-11......]   | [Water Main Ext..]   | [WM-2026]  |
+----------------------+----------------------+----------------------+-------------+
| Contractor           | Pipe Material        | Manufacturer         | Type Joint  |
| [Ajax Paving.....]   | [DIP CL 52.......]   | [US Pipe.........]   | [Push-on]  |
+----------------------+----------------------+----------------------+-------------+
```

## Pressure Test Pipe Section To Be Tested

Field order:

1. Required Test Pressure
2. Test Duration
3. Test Equip. at Location
4. Pipe row 1 Diameter (in.)
5. Pipe row 1 Length (feet)
6. Pipe row 2 Diameter (in.)
7. Pipe row 2 Length (feet)
8. Pipe row 3 Diameter (in.)
9. Pipe row 3 Length (feet)

### S21 Portrait

```text
+------------------------------------------------+
| B Pipe Section To Be Tested                 ^ |
| 150 psig - 2 hrs - 2 of 3 pipe rows            |
+-----------------------+------------------------+
| Required Test         | Test Duration          |
| Pressure, psig        | hrs.                   |
| [150.............]    | [2................]    |
+-----------------------+------------------------+
| Test Equip. at Location                         |
| [Hydrant at Sta. 12+50........................] |
+------------------------------------------------+
| Pipe sections                                  |
| Row | Diameter (in.) | Length (feet) | Edit    |
| 1   | 8              | 1120          | [Edit]  |
| 2   | 6              | 480           | [Edit]  |
| 3   | --             | --            | --      |
+-----------------------+------------------------+
| Next pipe section entry                       |
| Diameter (in.)        | Length (feet)          |
| [................]    | [................]     |
+-----------------------+------------------------+
| [Add pipe section row]                         |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| B Pipe Section To Be Tested                                                   ^  |
+----------------------+----------------------+------------------------------------+
| Required Test        | Test Duration        | Test Equip. at Location             |
| Pressure, psig       | hrs.                 | [Hydrant at Sta. 12+50..........]   |
| [150.............]   | [2...............]   |                                    |
+----------------------------------------------------------------------------------+
| Pipe sections                                                                  |
| Row | Diameter (in.) | Length (feet) | Allowable leakage gal/hr | Edit          |
| 1   | 8              | 1120          | 0.744                    | [Edit]        |
| 2   | 6              | 480           | 0.239                    | [Edit]        |
| 3   | --             | --            | --                       | --            |
+----------------------+----------------------+------------------------------------+
| Next pipe section entry                                                            |
| Diameter (in.)       | Length (feet)        |                                    |
| [................]   | [................]   | [Add pipe section row]             |
+----------------------+----------------------+------------------------------------+
```

Pipe row behavior:

- The app shows one pipe section entry composer.
- Add pipe section row writes to the next available printed row.
- Editing an existing row loads that row into the same composer and changes the
  action to Save pipe row N.
- The app never shows three separate repeated input groups at once.
- When all three printed pipe rows are filled, the add composer is hidden and
  the section shows `printed rows are full`.

### S21 Portrait - Pipe Rows Full

```text
+------------------------------------------------+
| B Pipe Section To Be Tested                 ^ |
| printed rows are full                         |
+------------------------------------------------+
| Pipe sections                                  |
| Row | Diameter (in.) | Length (feet) | Edit    |
| 1   | 8              | 1120          | [Edit]  |
| 2   | 6              | 480           | [Edit]  |
| 3   | 4              | 220           | [Edit]  |
+------------------------------------------------+
| printed rows are full                         |
+------------------------------------------------+
```

## Pressure Test Allowable Leakage Calculator

Printed formula factor:

```text
0.083 gal/inch of diameter/1000 ft. pipe/hour
```

App calculation:

```text
row_gal_per_hr = diameter_inches * length_feet / 1000 * 0.083
total_gal_per_1_hr = sum(row_gal_per_hr)
total_gal_for_duration = total_gal_per_1_hr * test_duration_hours
```

Required Test Pressure is editable and exported, but it does not change the
formula. The printed `0.083` factor is always used.

### S21 Portrait

```text
+------------------------------------------------+
| C Allowable Leakage                         ^ |
| 0.983 gal / 1 hr - 1.966 gal / 2 hrs          |
+------------------------------------------------+
| Factor                                         |
| 0.083 gal/inch diameter/1000 ft./hour          |
+------------------------------------------------+
| Row | Dia. | Length | Gal / 1 hr               |
| 1   | 8    | 1120   | 0.744                    |
| 2   | 6    | 480    | 0.239                    |
| 3   | --   | --     | --                       |
+-----------------------+------------------------+
| Total gal / 1 hr.     | Total gal / duration   |
| [0.983 calculated]    | [1.966 calculated]     |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| C Allowable Leakage                                                           ^  |
+----------------------------------------------------------------------------------+
| Factor: 0.083 gal/inch diameter/1000 ft. pipe/hour                              |
| Row | Diameter | Length | Row gal / 1 hr | Notes                                 |
| 1   | 8        | 1120   | 0.744          | calculated from pipe row              |
| 2   | 6        | 480    | 0.239          | calculated from pipe row              |
| 3   | --       | --     | --             | pending                               |
+----------------------+----------------------+------------------------------------+
| Total gal / 1 hr.    | Total gal / duration | Test duration                       |
| [0.983 calculated]   | [1.966 calculated]   | [2 hrs]                             |
+----------------------+----------------------+------------------------------------+
```

## Pressure Test Result Of Test

Field order per printed result row:

1. Time
2. Initial pressure
3. Final pressure
4. Meter Reading, gal

There are six printed result rows.

### S21 Portrait - Scan And Edit

```text
+------------------------------------------------+
| D Result Of Test                            ^ |
| 2 result rows - total loss pending             |
+------------------------------------------------+
| Result rows                                    |
| Row | Time  | Init psi | Final psi | Meter gal  |
| 1   | 8:00  | 150     | 150   | 12.0 [Edit]   |
| 2   | 10:00 | 148     | 148   | 13.2 [Edit]   |
| 3   | --    | --      | --    | --             |
+-----------------------+------------------------+
| Next test result entry                        |
| Time                  | Initial pressure       |
| [................]    | [................]     |
+-----------------------+------------------------+
| Final pressure        | Meter Reading, gal     |
| [................]    | [................]     |
+-----------------------+------------------------+
| [Add result row]                               |
+-----------------------+------------------------+
| Elapsed Time          | Total loss, gallons    |
| [2:00............]    | [1.2 calc/editable]    |
+-----------------------+------------------------+
| Total loss is calculated from meter readings   |
| when possible, but the field stays editable.   |
+------------------------------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| D Result Of Test                                                              ^  |
+----------------------------------------------------------------------------------+
| Row | Time  | Initial pressure | Final pressure | Meter Reading, gal | Edit      |
| 1   | 8:00  | 150     | 150   | 12.0               | [Edit]                      |
| 2   | 10:00 | 148     | 148   | 13.2               | [Edit]                      |
| 3   | --    | --      | --    | --                 | --                          |
| 4   | --    | --      | --    | --                 | --                          |
| 5   | --    | --      | --    | --                 | --                          |
| 6   | --    | --      | --    | --                 | --                          |
+----------------------+----------------------+----------------------+-------------+
| Next test result entry                                                           |
| Time                 | Initial pressure     | Final pressure       | Meter gal.  |
| [................]   | [................]   | [................]   | [.........] |
+----------------------+----------------------+----------------------+-------------+
| [Add result row]                                                                  |
+----------------------+----------------------+------------------------------------+
| Elapsed Time         | Total loss, gallons  |                                      |
| [2:00............]   | [1.2 calc/editable]  |                                      |
+----------------------+----------------------+------------------------------------+
```

Result row behavior:

- The app shows one result entry composer.
- Add result row writes to the next available printed row.
- Editing an existing row loads that row into the same composer and changes the
  action to Save result row N.
- The app never shows six separate repeated input groups at once.
- When all six printed result rows are filled, the add composer is hidden and
  the section shows `printed rows are full`.

### S21 Portrait - Result Rows Full

```text
+------------------------------------------------+
| D Result Of Test                            ^ |
| printed rows are full                         |
+------------------------------------------------+
| Result rows                                    |
| Row | Time  | Init psi | Final psi | Meter gal  |
| 1   | 8:00  | 150      | 150       | 12.0 [Edit]|
| 2   | 8:30  | 150      | 149       | 12.4 [Edit]|
| 3   | 9:00  | 149      | 149       | 12.7 [Edit]|
| 4   | 9:30  | 149      | 148       | 13.0 [Edit]|
| 5   | 10:00 | 148      | 148       | 13.2 [Edit]|
| 6   | 10:30 | 148      | 148       | 13.4 [Edit]|
+------------------------------------------------+
| printed rows are full                         |
+-----------------------+------------------------+
| Elapsed Time          | Total loss, gallons    |
| [2:30............]    | [1.4 calc/editable]    |
+-----------------------+------------------------+
```

## Pressure Test Remarks / Observer

Field order:

1. Remarks
2. Observer

### S21 Portrait

```text
+------------------------------------------------+
| E Remarks / Observer                        ^ |
| Observer pending                               |
+------------------------------------------------+
| Remarks                                        |
| +--------------------------------------------+ |
| | Test held two hours. No visible leaks.     | |
| |                                            | |
| |                                            | |
| +--------------------------------------------+ |
+-----------------------+------------------------+
| Observer              |                        |
| [Maria Lopez.....]    |                        |
+-----------------------+------------------------+
```

### Tablet Landscape

```text
+----------------------------------------------------------------------------------+
| E Remarks / Observer                                                           ^ |
+----------------------------------------------------------------------------------+
| Remarks                                                                          |
| +------------------------------------------------------------------------------+ |
| | Test held two hours. No visible leaks.                                        | |
| +------------------------------------------------------------------------------+ |
+----------------------+-----------------------------------------------------------+
| Observer             |                                                           |
| [Maria Lopez.....]   |                                                           |
+----------------------+-----------------------------------------------------------+
```

# MDOT 0582B Minimal Reference

No broad 0582B redesign is part of this package. Only these fields get trailing
`.0` cleanup:

1. Chart density
2. Chart moisture
3. Operating density
4. Operating moisture

# Implementation Acceptance Notes

- S21 portrait tests must prove short-entry fields render as two-column layouts
  for 1174R and 1126.
- Tablet tests must prove the wider grid/table layouts.
- Repeated-row tests must prove compact scan mode, edit-row mode, save, cancel,
  reopen, and updated summaries.
- 1174R Remarks / computations tests must prove one text box hydrates from
  older page-line data and splits back to the existing PDF fields.
- 1126 tests must prove compact header, rainfall, measures, and signature
  invalidation behavior.
- Pressure Test Report tests must prove S21 two-column entry, AcroForm template
  inventory, field mapping, allowable leakage calculation, result row editing,
  editable calculated total loss, preview flattening, export AcroForm
  preservation, and save/reopen/edit behavior.
- 0582B tests must prove only the four named fields drop trailing `.0`.
