        CIVILIZATION II TEST OF TIME (TM)
     PATCH RELEASE NOTES  September 20, 1999
    -----------------------------------------

We've fixed a bunch of things. Please note that your existing save files still work,
but the fixes will not be applied to saved games. New save files will reflect the changes
we've made.

Also, you must install this patch last. That means that if you have installed the official
Time Threat Paradox scenario since installing this patch, you must re-install the patch to 
get the changes to function.

Thank you.

1. There are a few new options:

	Graphics Options -- You can now toggle the Terrain Animations on and off.
	Edit Settings Menu (under Cheat / Scenario Parameters) -- Three new options
	  allow you to determine whether the various animations and the static unit
	  icons derived from them are used in your scenario. Note that when these are
	  set, the player cannot change them, not even with the graphics options. You
	  can lock out/override:

	* Terrain Animations: so that no special resources are animated.
	* Unit Animations: so moving units simply slide from place to place.
	* Static Units: so the unit icons are derived directly from units.bmp.

These items lock the settings they affect to whatever they where set as when the scenario
file is saved. In other words if you have the unit animation lockdown selected and your 
graphic options have animations turned on when you save your scenario they the animation 
for units will ALWAYS be on and cannot be modified. The opposite is true as well. For 
example if you have the terrain animations turned off and you set the lockout option then 
save your scenario then terrain animation will ALWAYS be off.

2. We believe we have fixed the problem in the Extended Game in which arriving at Centaurus
   did not result in any Colonist units or the ability to research Ultrastring Theory.

3. For events files, the Debug file (report.txt) now includes the amount of stack space
   left  for your use. Please note, however, that this total does NOT include the stack
   space needed by DELAYed events. Each DELAY adds 284 bytes to the space used. Overlapping
   DELAYs (those whose counters could be running at the same time) add up, but those that
   do not overlap do not-- i.e. they can re-use the same 284 bytes.

4. We have made a few modifications to the Fantasy and Midgard games:

	* The Thunderbolt unit can now move only 12, not 16 as before.
	* The Kraken is now more powerful, and might be armed. Also, its bribe price is up.
	* Subterranean tribes, when controlled by the AI, are more prolific than ever.
	* The Undersea version of Bedrock has been renamed Mantle Rock. (It was confusing.)
	* The game advice is now more relevant.
	* The Merfolk now receive the Deus Ex Machina wonder as a reward for successfully
	  completing the Ancient Dragon quest (as they were always meant to).
	

6. Units with spying abilities can no longer steal advances that a civilization is not
   allowed to possess.

7. The carrying capacity of ships is now noted in the Civilopedia entry for the unit.

8. You might notice that the Barbarians' non-transport ships are now more aggressive.

9. Event given abilities for building transport sites and for researching previously
   forbidden advances are now saved properly.

10. The last unused advanced unit bit flag in rules.txt has been assigned a role. When
    that '0' is set to '1', that unit (but no others) ignores all animation and reverts
    to the icon in units.bmp.

11. The issue with units starting on ocean tiles when playing a multi-map game using 
    premade maps has been adressed.

Plus we made a lot of minor fixes that most folks will never even notice, such as removing
the "Holds" numbers for submarine and carrier type units, since those numbers were ignored
by the program anyway.


	LICENSE AGREEMENT
	-----------------

	***   IMPORTANT  ***

This is a legal agreement between the end user ("You") and Hasbro Interactive, Inc., its
affiliates and subsidiaries (collectively "Hasbro Interactive").  This Agreement is part
of a package (the "Package") that also includes a CD-ROM  disc (collectively, the "CD-ROM")
and certain written materials (the "Documentation"). 

BY INSTALLING THE CD-ROM, YOU ACKNOWLEDGE THAT YOU HAVE READ ALL OF THE TERMS AND CONDITIONS
OF THIS AGREEMENT, UNDERSTAND THEM, AND AGREE TO BE BOUND BY THEM.  YOU UNDERSTAND THAT, IF
YOU PURCHASED THE PACKAGE FROM AN AUTHORIZED RESELLER OF HASBRO INTERACTIVE, THAT RESELLER
IS NOT HASBRO INTERACTIVE'S AGENT AND IS NOT AUTHORIZED TO MAKE ANY REPRESENTATIONS,
CONDITIONS OR WARRANTIES, STATUTORY OR OTHERWISE, ON HASBRO INTERACTIVE'S BEHALF NOR TO
VARY ANY OF THE TERMS OR CONDITIONS OF THIS AGREEMENT. 

If You do not agree to the terms of this Agreement, promptly return the entire Package to
the place You obtained it for a full refund.

LIMITED LICENSE:  You are entitled to use this CD-ROM for your own use, but may not sell or
transfer reproductions of the CD-ROM or Documentation to other parties in any way.  You may
use one copy of the CD-ROM on a single terminal connected to a single computer.  You may
not network the CD-ROM or otherwise use it on more than one computer or computer terminal
at the same time. 

OWNERSHIP; COPYRIGHT:  Title to the CD-ROM and the Documentation, and patents, copyrights
and all other property rights applicable thereto, shall at all times remain solely and
exclusively with Hasbro Interactive and its licensors, and You shall not take any action
inconsistent with such title. The CD-ROM and the Documentation are protected by United
States, Canadian and other applicable laws and by international treaty provisions.  Any
rights not expressly granted herein are reserved to Hasbro Interactive and its licensors. 
 
OTHER RESTRICTIONS:  You may not cause or permit the disclosure, copying, renting, licensing,
sublicensing, leasing, disseminating or otherwise distributing of the CD-ROM or the
Documentation by any means or in any form, without the prior written consent of Hasbro
Interactive.  You may not modify, enhance, supplement, create derivative work from, adapt,
translate, reverse engineer, decompile, disassemble or otherwise reduce the CD-ROM to human
readable form.  

	LIMITED WARRANTY:
	-----------------

Hasbro Interactive warrants for a period of ninety (90) days following original retail
purchase of this copy of the game that the CD-ROM is free from substantial errors or defects
that will materially interfere with the operation of the CD-ROM as described in the
Documentation.  This limited warranty applies to the initial purchaser only.  EXCEPT AS
STATED ABOVE, HASBRO INTERACTIVE MAKES NO OTHER WARRANTY OR CONDITION, EXPRESS OR IMPLIED,
STATUTORY OR OTHERWISE, REGARDING THIS CD-ROM.  THE IMPLIED WARRANTY THAT THE CD-ROM IS FIT
FOR A PARTICULAR PURPOSE AND THE IMPLIED WARRANTY OF MERCHANTABILITY SHALL BOTH BE LIMITED
TO THE NINETY (90) DAY DURATION OF THIS LIMITED EXPRESS WARRANTY.  THESE AND ANY OTHER
IMPLIED WARRANTIES OR CONDITIONS, STATUTORY OR OTHERWISE, ARE OTHERWISE EXPRESSLY AND
SPECIFICALLY DISCLAIMED.  Some jurisdictions do not allow limitations on how long an implied
warranty or condition lasts, so the above limitation may not apply to You.  This limited
warranty gives You specific legal rights, and you may also have other rights which vary
from jurisdiction to jurisdiction. 

If you believe you have found any such error or defect in the CD-ROM during the warranty
period, (i) if you are in the United States, call Hasbro Interactive's Consumer Affairs
Department at 800-683-5847 between the hours of 8:00 a.m. and 12:00 a.m midnight. Monday
through Friday (Eastern Time) and 8:00 a.m. to 8:00 p.m. Saturday and Sunday, holidays
excluded, and provide your Product number; or (ii) if you are outside the United States,
send your original CD-ROM disc to Hasbro Interactive at Caswell Way, Newport, Gwent, NP9
0YH, United Kingdom, together with a dated proof of purchase, your Product number, a brief
description of such error or defect and the address to which it is to be returned.  If you
have a problem resulting from a manufacturing defect in the CD-ROM, Hasbro Interactive's
entire liability and Your exclusive remedy for breach of this limited warranty shall be the
replacement of the CD-ROM, within a reasonable period of time and without charge, with a
corrected version of the CD-ROM.  Some jurisdictions do not allow the exclusion or
limitation of relief, incidental or consequential damages, so the above limitation or
exclusion may not apply to You.

HASBRO INTERACTIVE SHALL NOT BE LIABLE FOR SPECIAL, INCIDENTAL, CONSEQUENTIAL, EXEMPLARY OR
OTHER INDIRECT DAMAGES, EVEN IF HASBRO INTERACTIVE IS ADVISED OF OR AWARE OF THE POSSIBILITY
OF SUCH DAMAGES.  IN NO EVENT SHALL HASBRO INTERACTIVE'S LIABILITY EXCEED THE PURCHASE PRICE
OF THIS PACKAGE.  Some jurisdictions do not allow the exclusion or limitation of special,
incidental, consequential, indirect or exemplary damages, or the limitation of liability to
specified amounts, so the above limitation or exclusion may not apply to You.

GENERAL:  This Agreement constitutes the entire understanding between Hasbro Interactive
and You with respect to subject matter hereof.  Any change to this Agreement must be in
writing, signed by Hasbro Interactive and You.  Terms and conditions as set forth in any
purchase order which differ from, conflict with, or are not included in this Agreement,
shall not become part of this Agreement unless specifically accepted by Hasbro Interactive
in writing.  You shall be responsible for and shall pay, and shall reimburse Hasbro
Interactive on request if Hasbro Interactive is required to pay, any sales, use, value
added (VAT), consumption or other tax (excluding any tax that is based on Hasbro
Interactive's net income), assessment, duty, tariff, or other fee or charge of any kind or
nature that is levied or imposed by any governmental authority on the Package. 
 
EXPORT AND IMPORT COMPLIANCE:  In the event You export the CD-ROM or the Documentation from
the country in which You first received it, You assume the responsibility for compliance
with all applicable export and re-export regulations, as the case may be. 

GOVERNING LAW; ARBITRATION:  This Agreement shall be governed by, and any arbitration
hereunder shall apply, the laws of the Commonwealth of Massachusetts, U.S.A., excluding
(a) its conflicts of laws principles; (b) the United Nations Convention on Contracts for
the International Sale of Goods; (c) the 1974 Convention on the Limitation Period in the
International Sale of Goods; and (d) the Protocol amending the 1974 Convention, done at
Vienna April 11, 1980.  

Any dispute, controversy or claim arising out of or relating to this Agreement or to a
breach hereof, including its interpretation, performance or termination, shall be finally
resolved by arbitration.  The arbitration shall be conducted by three (3) arbitrators, one
to be appointed by Hasbro Interactive, one to be appointed by You and a third being
nominated by the two arbitrators so selected or, if they cannot agree on a third arbitrator,
by the President of the American Arbitration Association ("AAA").  The arbitration shall be
conducted in English and in accordance with the commercial arbitration rules of the AAA.
The arbitration, including the rendering of the award, shall take place in Boston,
Massachusetts, and shall be the exclusive forum for resolving such dispute, controversy or
claim.  The decision of the arbitrators shall be binding upon the parties hereto, and the
expense of the arbitration (including without limitation the award of attorneys' fees to
the prevailing party) shall be paid as the arbitrators determine.  The decision of the
arbitrators shall be executory, and judgment thereon may be entered by any court of
competent jurisdiction.  Notwithstanding anything contained in this Paragraph to the
contrary, Hasbro Interactive shall have the right to institute judicial proceedings against
You or anyone acting by, through or under You, in order to enforce Hasbro Interactive's
rights hereunder through reformation of contract, specific performance, injunction or
similar equitable relief.