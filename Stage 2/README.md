# PROJECT CHARTER
## Smart Medication Management System for Patients
### Stage 2 – Project Charter Development

**Prepared by:** Rama | Raghad | Amaal | Jana

**Date:** May–Jun 2026

---

## 1. Project Overview

The Smart Medication Management System for Elderly Patients is a healthcare-focused web and mobile application that aims to help elderly individuals manage their daily medications safely and effectively. The application provides medication tracking, scheduled reminders, and a daily adherence dashboard through a simplified, Arabic-first interface.

This project was selected based on a structured evaluation of multiple ideas during Stage 1. It achieved the highest score (28/30) and was unanimously chosen by the team for its strong real-world impact, alignment with team skills, and clear MVP scope.

---

## 2. Project Objectives

### 2.1 Purpose

The purpose of this project is to reduce medication errors and improve treatment adherence among elderly patients by providing a centralized, user-friendly digital solution for managing prescriptions and medication schedules.

### 2.2 SMART Objectives

**Objective 1 – Medication Management Feature**
- **Specific:** Develop a medication management module allowing users to add, view, and track medications with name, dosage, and schedule.
- **Measurable:** User can add at least 5 medications with complete details (name, dosage, schedule) in under 2 minutes.
- **Achievable:** Implementable using standard database and frontend technologies within the team's skill set.
- **Relevant:** Directly addresses the core problem of disorganized prescription tracking.
- **Time-bound:** Completed and tested within the designated development phase.

**Objective 2 – Reminder Notification System**
- **Specific:** Implement a scheduled notification system that alerts users when a medication is due or missed.
- **Measurable:** Notification system successfully delivers 95% of scheduled reminders within 1 minute of the scheduled time during testing.
- **Achievable:** Built using standard push notification frameworks available in the chosen tech stack.
- **Relevant:** Directly targets the problem of forgotten medication doses.
- **Time-bound:** Functional and tested by the end of the development phase.

**Objective 3 – Accessible User Interface**
- **Specific:** Design and deliver an Arabic-first interface with large text, simple navigation, and high-contrast visuals optimized for elderly users.
- **Measurable:** Interface passes basic usability review with large font sizes.
- **Achievable:** Achievable using standard UI frameworks and accessibility best practices.
- **Relevant:** Ensures the application is usable by the primary target audience.
- **Time-bound:** UI design finalized and implemented by the end of the development phase.

---

## 3. Stakeholders and Roles

### 3.1 Project Team Roles

All team members contribute as Full Stack Developers throughout the project. The roles below reflect organizational responsibilities alongside development duties.

### 3.2 Stakeholders

| Type | Stakeholder | Interest / Role |
|------|-------------|-----------------|
| Internal | Team Members | Design, develop, and deliver the MVP |
| Internal | Course Instructor / Tutor | Evaluate progress and provide academic guidance |
| External | Elderly Patients | Primary end-users of the application |
| External | Family Members / Caregivers | Secondary users who may assist elderly relatives |
| External | Healthcare Providers | Potential future integration partners (future scope) |

### 3.3 Team Roles

| Role | Member(s) | Responsibilities |
|------|-----------|-----------------|
| Project Manager | Raghad | Organize meetings, track tasks, ensure deadlines are met |
| Frontend Lead | Amaal | Research UI/UX ideas, design elderly-friendly interfaces |
| Backend Lead | Rama | Plan backend architecture and database structure |
| Designer | Jana | Create app branding, UI designs, wireframes, prototypes, and visual assets |
| Documentation Lead | Rama | Manage reports, meeting notes, and decision records |
| Research Coordinator | Jana | Conduct competitor analysis and gather user needs |

---

## 4. Project Scope

### 4.1 In-Scope

**User Interface:**
- Arabic-first user interface optimized for elderly accessibility (large fonts, simple navigation).
- Daily medication dashboard: overview of today's medications and adherence tracking.

**Technical Deliverables:**
- Frontend and backend development and integration.
- Basic testing and quality assurance of core features.
- Project documentation: charter, plan, and final report.

**Core Medication App:**
- Reminder notification system: scheduled alerts for medication times and missed dose notifications.
- Medication management: (add, view, edit, and delete) medications with name, dosage, and schedule.
- Drug interaction detection.
- User account management: registration and login.
- In-app medication search.
- Adherence rate calculation (taken / not taken).
- Post-dose prompt asking user if taken.
- Add dependents (children, spouse, elderly parents).
- Separate page for each dependent.
- Pill quantity tracking with low stock alert.
- Family or caregiver monitoring dashboard.
- Full tracking and analytics system for long-term missed medication patterns.

### 4.2 Out-of-Scope

- Direct hospital & pharmacy integration: syncing prescriptions automatically from clinics or hospitals.
- Wearable device integration: syncing with smartwatches to detect missed doses or health vitals.
- Multi-language support: expanding beyond Arabic to support other languages.
- Cloud-based medical history: storing and sharing full medical records across devices.
- Emergency alert system: notifying family members automatically if a critical dose is missed repeatedly.
- Medication cost tracking: helping users track spending on medications over time.

---

## 5. Risk Management

### 5.1 Introduction

Risk management is an essential part of project planning and development. The team focused on risks related to:

- Leadership and project safety
- User trust and adoption
- Technology and development
- Team dynamics and collaboration
- Scope and time management

### 5.2 Risk Assessment Table

| Risk | Probability | Impact | Mitigation Strategy |
|------|:-----------:|:------:|---------------------|
| Team members may lack experience with some technologies | Medium | Medium | Allocate learning time, share tutorials, support knowledge sharing |
| Delays due to limited project timeline | High | High | Focus only on core MVP features and create a clear task schedule |
| Notification reminders may not work consistently | Medium | High | Prioritize testing and implement stable reminder functionality early |
| Difficulty designing interfaces for elderly users | High | High | Use simple layouts, large fonts, and conduct usability testing |
| Miscommunication between team members | Medium | Medium | Hold regular meetings and maintain clear communication channels |
| Scope expansion beyond MVP requirements | Medium | High | Clearly define in-scope and out-of-scope features from the beginning |
| Healthcare workflows becoming too complex | Medium | Medium | Simplify workflows and avoid advanced healthcare integrations |
| Technical issues during development | Medium | Medium | Divide tasks into manageable phases and test continuously |
| Loss of project progress or documentation | Low | High | Use GitHub and cloud-based shared documentation tools regularly |
| UI may become too complicated for elderly users | Medium | High | Prioritize accessibility and simplicity in all UI/UX decisions |
| Competitors in the medication reminder space | High | High | Differentiate through dependent management and elderly-first Arabic design |
| Elderly users may lack basic technology literacy | High | High | Provide onboarding tutorial, printed user guide, and family-assisted setup |
| Low digital trust among elderly users | Medium | High | Emphasize free MVP, local data storage, and clear Arabic privacy policy |
| Family members may prefer existing solutions | Medium | Medium | Highlight added value: adherence tracking, missed dose reports, scheduling |

---

## 6. High-Level Project Plan

### 6.1 Purpose

To outline the major development phases, milestones, and deliverables for the Smart Medication Management System for Elderly Patients.

### 6.2 Project Timeline

| Stage | Duration | Activities | Key Deliverables |
|-------|----------|------------|-----------------|
| **Stage 1: Idea Development** | Week 1–2 | Team formation, brainstorming, research, idea evaluation, MVP selection | Finalized MVP idea, brainstorming documentation, evaluation matrix |
| **Stage 2: Project Charter Development** | Week 3–4 | Define project scope, objectives, stakeholders, risks, and project planning | Project Charter document |
| **Stage 3: Technical Documentation** | Week 5–6 | Create system requirements, use cases, UML diagrams, database design, UI wireframes | Technical documentation package |
| **Stage 4: MVP Development** | Week 7–10 | Frontend and backend development, database implementation, reminder system, testing, bug fixing | Functional MVP prototype |
| **Stage 5: Project Closure** | Week 11–12 | Project presentation, report submission, reflection | Final presentation and completed project |

### 6.3 Key Milestones

| Milestone | Expected Completion |
|-----------|-------------------|
| Team Formation Completed | End of Week 1 |
| MVP Idea Approved | End of Week 2 |
| Project Charter Finalized | End of Week 4 |
| Technical Documentation Completed | End of Week 6 |
| MVP Core Features Implemented | End of Week 9 |
| Final Testing Completed | Week 11 |
| Final Presentation and Submission | Week 12 |

### 6.4 Project Planning Approach

The team adopted a phased development approach to ensure the project remains manageable and achievable within the timeline. The project plan focuses on:

- Clear milestone tracking
- Balanced workload distribution
- Incremental development
- Continuous collaboration and communication
- Early identification of risks and challenges
