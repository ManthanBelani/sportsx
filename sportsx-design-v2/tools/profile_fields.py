#!/usr/bin/env python3
"""
SportX — profile field screens.

Renders the 6 profile sheets from SportX_Profile_Fields_Spec.md (6 roles x
30 fields = 180) as completion-driven profile screens in 09-profile-fields/.

Every field carries its priority (Essential / High / Medium) and its data type;
the renderer maps the data type onto the widget the spec shows in the PDF.
"""

import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "09-profile-fields")

# (number, label, section, priority, dtype, options/hint)
E, H, M = "Essential", "High", "Medium"

FIELDS = {
"athlete": ("Athlete", "Akshay Pandya", [
 (1,"Full Name","Basic Information",E,"text","Rohan Mehta — your official name"),
 (2,"Profile Photo","Basic Information",E,"image","Photo preview + Add Photo tile"),
 (3,"Primary Sport","Basic Information",E,"dropdown",["Cricket","Football","Badminton","Athletics","Swimming","Throwball"]),
 (4,"Position / Event","Basic Information",E,"dropdown",["Batsman (Right Hand)","Wicket Keeper","All Rounder","Fast Bowler","Spiker","Midfielder","Sprinter"]),
 (5,"City / State","Basic Information",E,"dropdown-pair",["Gujarat","Maharashtra","Karnataka","Rajasthan","Tamil Nadu"]),
 (6,"Age / Age Group","Basic Information",E,"agepair",["17 Years","18 Years","19 Years","20 Years"]),
 (7,"Skill / Playing Level","Basic Information",E,"dropdown",["Beginner","Developing","Intermediate","Advanced","Elite","Professional"]),
 (8,"Short Bio","Basic Information",E,"textarea","2–3 lines introduction"),
 (9,"Current Team / Academy","Team, Coach & Experience",H,"text","Ahmedabad Cricket Academy"),
 (10,"Coach","Team, Coach & Experience",H,"text","Rohit Mehta — optional but recommended"),
 (11,"Achievements","Performance & Achievements",H,"list",["State Level Winner — 2025","District Champion — 2024"]),
 (12,"Competition History","Performance & Achievements",H,"list",["Gujarat State Championship — 2025"]),
 (13,"Performance Statistics","Performance & Achievements",H,"statgrid",["Matches","Runs","Average","Strike Rate"]),
 (14,"Personal Best / Best Performance","Performance & Achievements",H,"text","Highest Score — 142"),
 (15,"Certificates","Performance & Achievements",H,"file",None),
 (16,"Years of Experience","Team, Coach & Experience",H,"dropdown",["1 Year","3 Years","5 Years","8 Years"]),
 (17,"Training Centre / Academy","Team, Coach & Experience",H,"text","Khel Academy, Ahmedabad"),
 (18,"Playing Hand / Foot","Physical Attributes",H,"dropdown",["Right-handed","Left-handed","Right-footed","Left-footed"]),
 (19,"Height","Physical Attributes",H,"unit",("178","cm",["cm","ft","in"])),
 (20,"Weight","Physical Attributes",M,"unit",("68","kg",["kg","lbs"])),
 (21,"Photos / Videos","Media & Visibility",H,"media-multi","Match photos, training videos, highlights"),
 (22,"Athlete Goals","Goals & Opportunities",H,"textarea","Short & long-term goals, e.g. State Team Selection"),
 (23,"Open to Opportunities","Goals & Opportunities",H,"checkbox-group",["Trials","Tournaments","Scholarships","Teams","Sponsorships","Academy Admission"]),
 (24,"Availability","Goals & Opportunities",H,"checkbox-group",["Weekdays","Weekends","Morning","Afternoon","Evening"]),
 (25,"Travel / Relocation Preference","Location & Travel",M,"dropdown",["Local (Within City/State)","State Level","National","International"]),
 (26,"Education / Institution","Education & Additional Sports",M,"text","Gujarat University"),
 (27,"Additional Sports","Education & Additional Sports",M,"multi-tag",["Football","Athletics","Badminton"]),
 (28,"Verification Status","Verification & Trust",M,"readonly-status",None),
 (29,"Sponsorship Interest","Goals & Opportunities",M,"dropdown",["Yes, I am interested","Not right now"]),
 (30,"Social / Professional Links","Social Links",M,"url-group",None),
]),
"coach": ("Coach", "Rohit Sharma", [
 (1,"Full Name","Basic Information",E,"text","Rohit Sharma"),
 (2,"Profile Photo","Basic Information",E,"image","Upload Photo"),
 (3,"Primary Sport","Basic Information",E,"dropdown",["Cricket","Football","Badminton","Athletics","Swimming"]),
 (4,"Coaching Specialization","Basic Information",E,"multi-tag",["Batting","Bowling","Fielding","Fitness","Goalkeeping"]),
 (5,"Coaching Level","Basic Information",E,"dropdown",["Grassroots","Youth","State","Professional"]),
 (6,"City / State","Basic Information",E,"dropdown-pair",["Gujarat","Maharashtra","Karnataka","Rajasthan"]),
 (7,"Short Bio","Basic Information",E,"textarea","2–3 lines about your coaching journey"),
 (8,"Years of Coaching Experience","Experience & Current Organization",E,"dropdown",["1–3 Years","4–6 Years","7–10 Years","12+ Years"]),
 (9,"Coaching Role","Experience & Current Organization",H,"dropdown",["Head Coach","Assistant Coach","Fitness Coach","Manager"]),
 (10,"Current Academy / Organization","Experience & Current Organization",H,"text","Ahmedabad Cricket Academy"),
 (11,"Qualifications / Certifications","Experience & Current Organization",H,"file",None),
 (12,"Teams Coached","Experience & Current Organization",H,"list",["Gujarat U-16 Team"]),
 (13,"Age Groups Coached","Coaching Focus",H,"checkbox-group",["U-8","U-10","U-12","U-14","U-16","U-18","U-21","Senior"]),
 (14,"Athlete Levels Coached","Coaching Focus",H,"checkbox-group",["Beginner","Developing","Intermediate","Advanced","Elite","Professional"]),
 (15,"Areas of Expertise","Coaching Focus",H,"checkbox-group",["Technical Skills","Tactical Development","Fitness & Conditioning","Mental Training","Youth Development","Match Preparation","Performance Analysis","Talent Development"]),
 (16,"Training Programs","Coaching Services & Programs",H,"list",["Beginner Program","Advanced Batting","Fitness Camp"]),
 (17,"Coaching Services","Coaching Services & Programs",H,"checkbox-group",["Individual","Group","Team","Camps / Workshops","Online","Trial Preparation","Competition Preparation","Fitness Training","Performance Analysis","Other"]),
 (18,"Availability","Availability & Location",H,"checkbox-group",["Weekdays","Weekends","Morning","Afternoon","Evening"]),
 (19,"Training Location","Availability & Location",H,"checkbox-plus-text",["Academy","Ground","Indoor Facility","Gym","Online","Other"]),
 (20,"Coaching Achievements","Achievements & Impact",H,"list",["State Championship Winner — 2024"]),
 (21,"Athletes / Teams Coached","Achievements & Impact",H,"stats",["State-level players","National selections","Years mentoring"]),
 (22,"Photos & Videos","Media & Presence",H,"media-multi","Training, matches, camps"),
 (23,"Coaching Philosophy","Professional Details",M,"textarea","Fundamentals, discipline, long-term development"),
 (24,"Fees / Pricing","Professional Details",M,"dropdown",["Per Session","Monthly Program","Contact for Fees"]),
 (25,"Open to Opportunities","Professional Details",M,"checkbox-group",["Academy Position","Team Coach","School / College","Camps / Workshops","Consulting","Other"]),
 (26,"Travel / Relocation Preference","Professional Details",M,"dropdown",["Local","State","National","International"]),
 (27,"Education","Education",M,"text","B.Com, Gujarat University"),
 (28,"Reviews / Recommendations","Reviews & Verification",M,"readonly-rating",("4.5","20 reviews")),
 (29,"Verification Status","Reviews & Verification",M,"readonly-status",None),
 (30,"Social / Professional Links","Social Links",M,"url-group",None),
]),
"academy": ("Academy", "Khel Cricket Academy", [
 (1,"Academy Name","Basic Information",E,"text","Khel Cricket Academy"),
 (2,"Academy Logo / Cover Photo","Basic Information",E,"image","Upload Logo"),
 (3,"Primary Sport(s)","Basic Information",E,"multi-tag",["Cricket","Football","Badminton","Swimming"]),
 (4,"Academy Type","Basic Information",E,"dropdown",["Private","Club","School","College","Government","NGO"]),
 (5,"City / State (Location)","Basic Information",E,"dropdown-pair",["Gujarat","Maharashtra","Karnataka","Rajasthan"]),
 (6,"Short Description","Basic Information",E,"textarea","2–3 lines"),
 (7,"Sports / Training Offered","Sports & Training Details",E,"multi-tag",["Batting","Bowling","Fielding","Fitness","Strategy"]),
 (8,"Age Groups","Sports & Training Details",E,"checkbox-group",["U-6","U-8","U-10","U-12","U-14","U-16","U-18","Senior"]),
 (9,"Training Programs","Sports & Training Details",E,"list",["Beginner Program (3 Months)","Advanced (6 Months)","Elite (1 Year)"]),
 (10,"Coaches / Coaching Team","Coaching Team",H,"profilecards",None),
 (11,"Years Established","Academy Details",H,"year",None),
 (12,"Facilities","Academy Details",H,"checkbox-group",["Ground","Nets","Indoor Facility","Gym","Video Analysis","Changing Room","Parking","First Aid","Other"]),
 (13,"Training Schedule","Academy Details",H,"dropdown",["Morning & Evening Batches","Morning Only","Evening Only","Flexible"]),
 (14,"Training Location / Address","Academy Details",H,"textarea",None),
 (15,"Fees / Pricing","Academy Details",H,"fees",None),
 (16,"Admission / Registration Process","Admission & Contact",H,"dropdown",["Trial Required","Direct Admission","Interview","Online Form"]),
 (17,"Academy Achievements","Achievements & Outcomes",H,"list",["Gujarat State Champions — U16 (2024)"]),
 (18,"Athletes / Teams Developed","Achievements & Outcomes",H,"stats",["Trained Athletes","State Selections","National Selections"]),
 (19,"Competitions / Tournaments","Opportunities & Events",H,"list",["Gujarat Inter-Academy Cup — 2025"]),
 (20,"Trials / Open Registrations","Opportunities & Events",H,"list",["U-14 Cricket Trials — 12 Oct 2026"]),
 (21,"Photos & Videos","Media & Gallery",H,"media-multi","Academy photos, training videos, facilities, events"),
 (22,"Verification Status","Verification & Credentials",H,"readonly-status",None),
 (23,"Contact / Enquiry","Admission & Contact",H,"contact",None),
 (24,"Website / Social Links","Additional Information",M,"url-group",None),
 (25,"Reviews / Recommendations","Additional Information",M,"readonly-rating",("4.5","120 reviews")),
 (26,"Academy Head / Owner","Additional Information",M,"linkedtext","Amit Patel — Founder & Director"),
 (27,"Certifications / Affiliations","Verification & Credentials",M,"multi-tag",["BCCI Affiliated","Gujarat Cricket Association","Sports Authority of Gujarat"]),
 (28,"Scholarships / Financial Aid","Opportunities & Events",M,"dropdown",["Merit-based scholarships available","Not available"]),
 (29,"Accommodation / Transport","Additional Information",M,"dropdown",["Transport Available","Hostel Available","Both","None"]),
 (30,"Open Opportunities","Opportunities & Events",M,"dropdown",["Coach Recruitment","Partnership","Fundraising","Not Open"]),
]),
"scout": ("Talent Scout", "Rohit Kumar", [
 (1,"Full Name","Basic Information",E,"text","Rohit Kumar"),
 (2,"Profile Photo / Cover","Basic Information",E,"image","Upload Photo"),
 (3,"Scout Type","Basic Information",E,"dropdown",["Independent Scout","Club Scout","Academy Scout","Federation Scout"]),
 (4,"Primary Sport(s)","Basic Information",E,"multi-tag",["Cricket","Football","Badminton","Athletics"]),
 (5,"Scouting Specialization / Position","Basic Information",E,"multi-tag",["Batting","Bowling","Wicketkeeping","Midfielder","Goalkeeper","Sprinter"]),
 (6,"City / State (Base Location)","Basic Information",E,"dropdown-pair",["Gujarat","Maharashtra","Karnataka","Rajasthan"]),
 (7,"Short Bio","Basic Information",E,"textarea","2–3 lines"),
 (8,"Years of Scouting Experience","Experience & Organization",H,"dropdown",["1–3 Years","5+ Years","8+ Years"]),
 (9,"Scouting Level","Experience & Organization",H,"checkbox-group",["Grassroots","School","College","Club","District","State","National","Professional"]),
 (10,"Age Groups Scouted","Experience & Organization",H,"checkbox-group",["U-8","U-10","U-12","U-14","U-16","U-18","U-21","Senior"]),
 (11,"Current Organization / Club","Experience & Organization",H,"text","Gujarat Cricket Association"),
 (12,"Previous Organizations / Teams","Experience & Organization",H,"list",["Rajasthan Royals (Talent Scout) 2022–2024"]),
 (13,"Certifications / Qualifications","Qualifications & Method",H,"list",["AIFF Talent Identification Certificate 2023"]),
 (14,"Scouting Method","Qualifications & Method",H,"checkbox-group",["Live Match Scouting","Video Analysis","Training Observation","Statistical Analysis","Trial Assessment","Combine Testing","Coach Recommendations","Other"]),
 (15,"Evaluation Areas","Qualifications & Method",H,"checkbox-group",["Technical Ability","Tactical Understanding","Physical Fitness","Mental Attributes","Potential","Consistency","Game Awareness","Decision Making"]),
 (16,"Athletes Scouted","Track Record",H,"stats",["Total Athletes","State Level","National Level"]),
 (17,"Successful Talent Discoveries","Track Record",H,"list",["Player selected for Gujarat State Team — 2024"]),
 (18,"Scouting Achievements","Track Record",H,"list",["Best Talent Scout Award — Gujarat 2024"]),
 (19,"Scouting Regions / Travel Availability","Scouting Coverage",H,"checkbox-group",["Local","District","State","National","International"]),
 (20,"Scouting Events / Matches Covered","Scouting Coverage",H,"multi-tag",["Tournaments","Trials","Leagues","Schools","College Events","Camps"]),
 (21,"Services Offered","Scouting Coverage",H,"checkbox-group",["Talent Identification","Video Analysis","Recruitment Scouting","Academy Collaboration","Player Evaluation Reports","Trial Organization","Match Scouting","Other"]),
 (22,"Recruitment Focus","Scouting Coverage",H,"multi-tag",["Academy Admissions","Team Selection","Scholarships","Professional Contracts"]),
 (23,"Scouting Reports / Portfolio","Scouting Coverage",H,"stats",["Scouting Reports","Player Assessments","Video Analyses"]),
 (24,"Photos & Videos","Media & Presence",M,"media-multi","Match photos, scouting videos, events"),
 (25,"Professional Recommendations","Professional Network",M,"readonly-rating",("4.7","18 reviews")),
 (26,"Verification Status","Professional Network",M,"readonly-status",None),
 (27,"Professional Network / Affiliations","Professional Network",M,"multi-tag",["Clubs","Academies","Federations","Agents"]),
 (28,"Availability","Professional Network",M,"dropdown",["Available for Scouting","Limited Availability","Not Available"]),
 (29,"Website / Social Links","Professional Network",M,"url-group",None),
 (30,"Professional Services / Fees","Professional Network",M,"dropdown",["Contact for Pricing","Per Report","Retainer","Free"]),
]),
"organizer": ("Organizer", "Gujarat Sports Events", [
 (1,"Organizer / Organization Name","Basic Information",E,"text","Gujarat Sports Events"),
 (2,"Logo / Cover Photo","Basic Information",E,"image","Upload Logo"),
 (3,"Organizer Type","Basic Information",E,"dropdown",["Event Company","Individual","Club","College","Federation","NGO"]),
 (4,"Primary Sport(s)","Basic Information",E,"multi-tag",["Cricket","Football","Volleyball","Athletics","Throwball"]),
 (5,"Event Types","Basic Information",E,"checkbox-group",["Tournament","Trial","Championship","Camp","League","Workshop","Sports Meet","Marathon","Other"]),
 (6,"City / State (Base Location)","Basic Information",E,"dropdown-pair",["Gujarat","Maharashtra","Karnataka","Rajasthan"]),
 (7,"Short Description","Basic Information",E,"textarea","2–3 lines"),
 (8,"Years of Experience","Experience & Event History",H,"dropdown",["1–3 Years","5+ Years","10+ Years"]),
 (9,"Events Organized (History)","Experience & Event History",H,"list",["Gujarat Inter-Academy Cup — 2025"]),
 (10,"Competition Level","Experience & Event History",H,"checkbox-group",["School","College","Club","District","State","National","International","Amateur","Professional"]),
 (11,"Upcoming Events","Upcoming Events",H,"list",["Gujarat Youth Football Championship — 20 Nov 2026"]),
 (12,"Event Registration","Upcoming Events",H,"radio",["Individual Registration","Team Registration","Both"]),
 (13,"Eligibility Criteria","Upcoming Events",H,"multi-tag",["U-14","U-16","U-19","Open"]),
 (14,"Event Date & Venue","Upcoming Events",H,"daterange",None),
 (15,"Registration Fee","Upcoming Events",H,"currency",None),
 (16,"Registration Deadline","Upcoming Events",H,"date",None),
 (17,"Participants / Teams","Participants & Venue",H,"stats",["Participants","Teams","Academies"]),
 (18,"Venue Details","Participants & Venue",H,"checkbox-group",["Ground","Changing Room","Parking","Drinking Water","Seating","First Aid"]),
 (19,"Schedule / Fixtures","Participants & Venue",H,"list",["15 Nov — Group Matches","16 Nov — Knockouts","20 Nov — Final"]),
 (20,"Results / Winners","Results & Achievements",H,"list",["2025 Gujarat Inter-Academy Cup — Champions"]),
 (21,"Achievements","Results & Achievements",H,"list",["Organized 20+ events, 5000+ athletes participated"]),
 (22,"Contact / Enquiry","Contact & Verification",H,"contact",None),
 (23,"Verification Status","Contact & Verification",H,"readonly-status",None),
 (24,"Photos & Videos","Media & Gallery",H,"media-multi","Event photos, videos, posters, highlights"),
 (25,"Partners / Affiliations","Partners & Sponsors",M,"logorow",None),
 (26,"Sponsors","Partners & Sponsors",M,"logorow",None),
 (27,"Opportunities Offered","Opportunities",M,"checkbox-group",["Trials","Team Selection","Camps","Volunteer","Scholarships","Coaching Jobs"]),
 (28,"Reviews / Recommendations","Additional Information",M,"readonly-rating",("4.5","32 reviews")),
 (29,"Website / Social Links","Additional Information",M,"url-group",None),
 (30,"Organizer / Contact Person","Additional Information",M,"linkedtext","Amit Patel — Founder & Event Director"),
]),
"generalized": ("Generalized", "FitYouth Foundation", [
 (1,"Profile Type / Category","Identity & Basic Information",E,"dropdown",["NGO","Doctor","Physiotherapist","Sports Store","Brand","Nutritionist","Journalist","Agent","Federation","Facility","School / College","Sports Psychologist","Sports Photographer","Event Company","Government Body","Other"]),
 (2,"Name (Individual / Organization)","Identity & Basic Information",E,"text","Full name or business name"),
 (3,"Profile Photo / Logo","Identity & Basic Information",E,"image","Photo or logo + cover image"),
 (4,"Short Description (About)","Identity & Basic Information",E,"textarea","What you do, mission, focus areas (2–3 lines)"),
 (5,"Primary Sport(s)","Sports & Specialization",E,"multi-tag",["Cricket","Football","Badminton","Athletics","Multi-Sport"]),
 (6,"Services / Products Specialization","Sports & Specialization",E,"multi-tag",["Sports Medicine","Equipment","Nutrition","Grassroots Development","Rehabilitation"]),
 (7,"Target Audience","Sports & Specialization",H,"multi-tag",["Athletes","Coaches","Academies","Teams","Schools","General Public"]),
 (8,"Primary Location (City/State)","Location",E,"dropdown-pair",["Gujarat","Maharashtra","Karnataka","Rajasthan","Delhi"]),
 (9,"Service / Operating Area","Location",H,"dropdown",["Local","District","State","National","International"]),
 (10,"Branches / Multiple Locations","Location",M,"list",["Vadodara Branch"]),
 (11,"Contact Information","Contact Information",E,"contact",None),
 (12,"Contact Person","Contact Information",H,"text","Name, designation (for organizations)"),
 (13,"Website / Social Links","Contact Information",H,"url-group",None),
 (14,"Organization Type","Organization / Professional Details",H,"dropdown",["Private","NGO","Government","Company","Individual Professional"]),
 (15,"Established Year","Organization / Professional Details",H,"year",None),
 (16,"Founder / Owner / Head","Organization / Professional Details",H,"text","Name and position"),
 (17,"Team / Staff","Organization / Professional Details",M,"list",["Core team member — role"]),
 (18,"Services Offered","Services / Products / Programs",E,"multi-tag",["Consultation","Rehabilitation","Equipment","Training Program","Community Program"]),
 (19,"Products Offered (if applicable)","Services / Products / Programs",H,"list",["Sports equipment","Apparel","Accessories"]),
 (20,"Programs (if applicable)","Services / Products / Programs",H,"list",["Training program","Community program","Health program"]),
 (21,"Professional Qualifications","Qualifications & Experience",H,"text","Degree, certification, specialization"),
 (22,"Certifications","Qualifications & Experience",H,"file",None),
 (23,"Professional Experience","Qualifications & Experience",H,"dropdown",["1–3 Years","5+ Years","10+ Years"]),
 (24,"Achievements","Achievements & Track Record",H,"list",["Award or recognition — 2025"]),
 (25,"Work / Project History","Achievements & Track Record",M,"list",["Project or event worked on — 2024"]),
 (26,"Verification Status","Trust & Verification",H,"readonly-status",None),
 (27,"Documents","Trust & Verification",M,"file",None),
 (28,"Availability","Availability & Service Mode",M,"dropdown",["Available","Limited","Not available"]),
 (29,"Service Mode","Availability & Service Mode",M,"dropdown",["Online","Offline","Both","Home Visit"]),
 (30,"Partnerships / Affiliations","Network & Partnerships",M,"multi-tag",["Academies","Brands","Federations","Government"]),
]),
}

CHECKLIST = {
 "athlete": "Basic Information, Sport & Position, Achievements, Statistics, Media, Goals & Opportunities",
 "coach": "Basic Information, Coaching Details, Qualifications, Experience, Programs & Services, Achievements, Media, Verification",
 "academy": "Basic Information, Sports & Training, Coaches, Facilities, Programs, Achievements, Media, Verification",
 "scout": "Basic Information, Experience & Organization, Qualifications, Scouting Coverage, Track Record, Media & Presence, Network & Links, Verification",
 "generalized": "Identity, Sports & Specialization, Location, Contact, Services, Qualifications, Trust & Verification",
 "organizer": "Basic Information, Sports & Event Details, Experience, Upcoming Events, Venue & Schedule, Results & Achievements, Media, Verification",
}

PRIO_STYLE = {
    E: ("--red-tint", "#B91C1C", "Essential"),
    H: ("var(--primary-soft)", "#7A5A00", "High"),
    M: ("var(--green-tint)", "#15803D", "Medium"),
}

STATES = ["Gujarat", "Maharashtra", "Karnataka", "Rajasthan", "Tamil Nadu", "Delhi", "Uttar Pradesh"]


def sel(label, opts, cls="inp"):
    o = "".join(f"<option>{x}</option>" for x in opts)
    return f'<select class="{cls}"><option>Select {label}</option>{o}</select>'


def chips(opts, on=1):
    out = []
    for i, o in enumerate(opts):
        out.append(f'<span class="chip{" soft" if i < on else ""}">{o}</span>')
    return '<div class="checks">' + "".join(out) + "</div>"


def rows(items):
    return "".join(
        f'<div class="listrow"><input class="inp" value="{i}">'
        f'<button class="rowdel" aria-label="Remove"><i data-lucide="x"></i></button></div>'
        for i in items)


def widget(dtype, hint, fid, name=""):
    """Map a spec data type onto the widget the PDF shows."""
    if dtype == "text":
        return f'<input class="inp" placeholder="{hint}">'
    if dtype == "textarea":
        return f'<textarea class="inp" placeholder="{hint}"></textarea>'
    if dtype == "dropdown":
        return sel(name, hint)
    if dtype == "dropdown-pair":
        return f'<div class="pair">{sel("State", STATES)}{sel("City", ["Ahmedabad","Vadodara","Surat","Rajkot"])}</div>'
    if dtype == "agepair":
        return f'<div class="pair">{sel("Age in years", hint)}{sel("Age Group", ["U-14","U-16","U-17","U-19","Senior"])}</div>'
    if dtype == "multi-tag":
        return chips(hint, 2)
    if dtype == "checkbox-group":
        return chips(hint, 1)
    if dtype == "checkbox-plus-text":
        return chips(hint, 2) + '<input class="inp mt8" placeholder="Venue name">'
    if dtype == "radio":
        return "".join(
            f'<label class="radio"><input type="radio" name="r{fid}"{" checked" if i == 0 else ""}>{o}</label>'
            for i, o in enumerate(hint))
    if dtype == "image":
        return ('<div class="uploaderow"><div class="upbox filled"><i data-lucide="user"></i></div>'
                '<div class="upbox"><i data-lucide="plus"></i><span>Add Photo</span></div></div>')
    if dtype == "file":
        return '<button class="btn btn-sec btn-sm"><i data-lucide="upload"></i>Upload Certificate</button>'
    if dtype == "media-multi":
        return ('<div class="medgrid"><div><img src="https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=300&q=60" alt="" onerror="this.remove()"></div>'
                '<div><img src="https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=300&q=60" alt="" onerror="this.remove()"></div>'
                '<div style="background:var(--surface);color:var(--muted);flex-direction:column;gap:4px">'
                '<i data-lucide="plus"></i><span style="font-size:9px;font-weight:700">Add</span></div></div>')
    if dtype == "list":
        return rows(hint) + f'<button class="btn btn-dashed btn-sm mt8"><i data-lucide="plus"></i>Add row</button>'
    if dtype == "statgrid":
        return '<div class="statgrid">' + "".join(
            f'<div><b>0</b><span>{x}</span></div>' for x in hint) + "</div>"
    if dtype == "stats":
        return '<div class="statgrid">' + "".join(
            f'<div><b>0</b><span>{x}</span></div>' for x in hint) + "</div>"
    if dtype == "url-group":
        return '<div class="dlist">' + "".join(
            f'<div><i data-lucide="{ic}"></i><input class="inp inp-flush" placeholder="{lb}"></div>'
            for ic, lb in [("instagram", "Instagram (@username)"), ("youtube", "YouTube (@channel)"),
                           ("linkedin", "LinkedIn"), ("globe", "Website")]) + "</div>"
    if dtype == "contact":
        return ('<div class="pair"><input class="inp" placeholder="+91 98765 43210"></div>'
                '<input class="inp mt8" placeholder="Email address">'
                '<div class="tile mt8"><span class="tic" style="background:var(--green-tint);color:var(--green)">'
                '<i data-lucide="message-circle"></i></span><b>WhatsApp</b></div>')
    if dtype == "year":
        return '<input class="inp" type="number" placeholder="e.g. 2018" inputmode="numeric">'
    if dtype == "date":
        return '<input class="inp" type="date">'
    if dtype == "daterange":
        return ('<div class="pair"><input class="inp" type="date"><input class="inp" type="date"></div>'
                '<textarea class="inp mt8" placeholder="Venue — e.g. Narendra Modi Stadium, Ahmedabad"></textarea>')
    if dtype == "currency":
        return ('<div class="pair"><input class="inp" type="number" placeholder="500">'
                '<select class="inp"><option>INR</option><option>USD</option></select></div>'
                '<p class="hint">Per player / team</p>')
    if dtype == "unit":
        val, unit, units = hint
        return (f'<div class="pair"><input class="inp" type="number" value="{val}">'
                f'{sel(unit, units)}</div>')
    if dtype == "fees":
        return ('<label class="switchrow"><input type="checkbox" checked><span class="sw"></span>'
                '<b>Show Fees on Profile</b></label>'
                '<input class="inp mt8" placeholder="e.g. ₹3,000 / month (Beginner Program)">')
    if dtype == "linkedtext":
        return f'<input class="inp" placeholder="{hint}">'
    if dtype == "profilecards":
        return ('<div class="listrow"><div class="avatar av40">R</div>'
                '<input class="inp" value="Rohit Mehta — Head Coach — 10+ yrs"></div>'
                '<button class="btn btn-dashed btn-sm mt8"><i data-lucide="plus"></i>Add Coach</button>')
    if dtype == "logorow":
        return ('<div class="logorow"><span>Federation</span><span>Brand</span><span>Academy</span>'
                '<button class="rowdel"><i data-lucide="plus"></i></button></div>')
    if dtype == "readonly-status":
        return '<span class="pill pill-draft"><i data-lucide="shield-check" style="width:12px;height:12px"></i>Not Verified Yet</span>'
    if dtype == "readonly-rating":
        sc, n = hint
        return (f'<div class="rating" style="font-size:14px"><i data-lucide="star"></i>{sc} '
                f'<span style="color:var(--muted);font-weight:500">({n})</span></div>'
                '<a class="seeall link" href="#" style="margin-top:4px">View All</a>')
    return ""


def render(role):
    label, person, fields = FIELDS[role]
    counts = {p: sum(1 for f in fields if f[3] == p) for p in (E, H, M)}
    done_pct = 60

    # group by section, preserving first-seen order
    order, bysec = [], {}
    for f in fields:
        if f[2] not in bysec:
            bysec[f[2]] = []
            order.append(f[2])
        bysec[f[2]].append(f)

    body = []
    for sec in order:
        body.append(f'<h2 class="formsec">{sec}</h2>')
        for num, name, _s, prio, dtype, hint in bysec[sec]:
            bg, fg, plabel = PRIO_STYLE[prio]
            body.append(f'''<div class="field">
<div class="field-h"><span class="fnum">{num}</span><b>{name}</b>
<span class="prio" style="background:{bg};color:{fg}">{plabel}</span></div>
{widget(dtype, hint, num, name)}</div>''')

    prio_legend = "".join(
        f'<span class="prio" style="background:{PRIO_STYLE[p][0]};color:{PRIO_STYLE[p][1]}">{p}</span>'
        for p in (E, H, M))

    return f'''<!DOCTYPE html><html lang="en"><head><title>{label} Profile - SportX</title><meta charset="UTF-8"><link rel="icon" href="../assets/images/logo.png" type="image/png"><meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Sora:wght@500;600;700;800&display=swap" rel="stylesheet">
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.min.js"></script><link rel="stylesheet" href="../assets/css/sportx.css"></head>
<body><div class="phone">
<div class="statusbar"><span class="sb-time">9:41</span><span class="sb-right"><i data-lucide="signal"></i><i data-lucide="wifi"></i><i data-lucide="battery-full"></i></span></div>
<div class="topbar"><a class="iconbtn" href="../01-athlete/more.html"><i data-lucide="arrow-left"></i></a><h1>{label} Profile</h1><span style="width:40px"></span></div>
<div class="content">

<div class="greet" style="padding:16px">
<div style="display:flex;gap:13px;align-items:center">
<div class="ring"><svg width="62" height="62" viewBox="0 0 62 62"><circle cx="31" cy="31" r="26" fill="none" stroke="#E6EAF2" stroke-width="6"/><circle cx="31" cy="31" r="26" fill="none" stroke="#FFC72C" stroke-width="6" stroke-linecap="round" stroke-dasharray="163" stroke-dashoffset="65"/></svg><span class="ringtxt" style="inset:0;display:grid;place-items:center">{done_pct}%</span></div>
<div style="flex:1;min-width:0"><b style="font-size:15.5px;color:var(--navy)">{person}</b>
<p style="font-size:12px;color:var(--muted);margin-top:2px">Complete your profile to unlock more opportunities</p>
<div style="display:flex;gap:6px;margin-top:7px">{prio_legend}</div></div></div>
<div class="pbar"><i style="width:{done_pct}%"></i></div>
<div class="statgrid" style="margin-top:12px">
<div><b>{counts[E]}</b><span>Essential</span></div>
<div><b>{counts[H]}</b><span>High</span></div>
<div><b>{counts[M]}</b><span>Medium</span></div>
<div><b>30</b><span>Total</span></div></div></div>

{"".join(body)}

<div class="card mt16" style="background:var(--surface);border-style:dashed">
<b style="font-size:13px;color:var(--navy);display:block;margin-bottom:4px">Profile Completion Guide</b>
<p style="font-size:12px;color:var(--muted);line-height:1.5">{CHECKLIST[role]}</p></div>

<button class="btn btn-pri btn-block">Complete Profile <i data-lucide="arrow-right"></i></button>
</div><script>lucide.createIcons();</script></body></html>
'''


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for role in FIELDS:
        p = os.path.join(OUT, f"profile-{role}.html")
        open(p, "w", encoding="utf-8").write(render(role))
        n = len(FIELDS[role][2])
        total += n
        print(f"  {p}  ({n} fields)")
    print(f"total fields rendered: {total}")
