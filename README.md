#  Complete Project Response - Phase 1 Report

##  Executive Summary

### Project Overview

**Project Title:**  
Smart Medication Management System for Elderly Patients — **Dawai (دوائي)**

**Team Members:**
- **Rama** - Backend Developer, SCM Manager
- **Raghad** - Backend Developer, Project Manager, QA
- **Jana** - Frontend Developer, Documentation Lead
- **Amaal** - Frontend Developer

**Objective:**  
Develop a healthcare application that helps elderly patients manage their medications safely and effectively, with an easy-to-use Arabic-first interface, reminder system, and adherence tracking.

---

##  Table of Contents

- [1. Team Formation & Management](#1-team-formation--management)
- [2. Research & Brainstorming](#2-research--brainstorming)
- [3. Idea Evaluation](#3-idea-evaluation)
- [4. Final Decision & MVP Refinement](#4-final-decision--mvp-refinement)
- [5. Risk Assessment](#5-risk-assessment)
- [6. Project Timeline](#6-project-timeline)
- [7. Code Management Strategy](#7-code-management-strategy)
- [8. Quality Assurance Strategy](#8-quality-assurance-strategy)
- [9. Test Results](#9-test-results)
- [10. References](#10-references)
- [11. Conclusion](#11-conclusion)

---

## 1. Team Formation & Management

### 1.1 Team Formation

The team held an initial kickoff meeting to introduce members, discuss technical backgrounds, interests, and project goals.

### 1.2 Initial Roles Assigned

| Member | Primary Role | Responsibilities |
|--------|--------------|------------------|
| **Rama** | Project Manager, Backend Developer | Organizing meetings, task tracking, deadline management |
| **Raghad** | Project Manager, Backend Developer | Quality assurance, meeting coordination |
| **Jana** | Frontend Developer, Documentation | UI/UX design, decision documentation |
| **Amaal** | Frontend Developer | UI implementation, UX design |

### 1.3 Collaboration Strategy

-  Weekly online meetings
-  Daily communication via Discord/WhatsApp
-  Shared documentation using Google Docs & Notion
-  Task tracking using Trello/GitHub Projects
-  Democratic decision-making through discussion & voting

### 1.4 Team Norms

- Respect all ideas during brainstorming
- Encourage equal participation
- Maintain clear and professional communication
- Complete tasks before deadlines
- Resolve disagreements through discussion and evidence

---

## 2. Research & Brainstorming

### 2.1 Research Process

The team explored project opportunities based on:
- Real-world problems affecting daily life
- Current technology and healthcare trends
- Existing applications and market gaps
- User pain points in Saudi society
- Feasible solutions for MVP development

### 2.2 Brainstorming Techniques

#### A. Mind Mapping

**Central Problem:** Difficulty Managing Medications for Elderly Patients

**Related Challenges:**
- Forgetting medication times
- Multiple prescriptions from different hospitals
- Drug interaction risks
- Difficulty understanding medication schedules
- Lack of centralized medication records

**Possible Solutions:**
- Medication reminder system
- Daily medication dashboard
- Unified medication history
- Simple Arabic-first interface
- Alert notifications for missed doses

#### B. SCAMPER Framework

| SCAMPER Element | Application to the Idea |
|-----------------|-------------------------|
| **Substitute** | Replace paper schedules with digital reminders |
| **Combine** | Combine medication tracking with adherence monitoring |
| **Adapt** | Adapt fitness app reminder systems for healthcare |
| **Modify** | Simplify interfaces specifically for elderly users |
| **Put to Another Use** | Use notification systems for healthcare safety alerts |
| **Eliminate** | Remove unnecessary complex features from MVP |
| **Reverse** | Design the app around user simplicity instead of feature complexity |

#### C. "How Might We" Questions

- How might we help elderly users remember medications easily?
- How might we reduce medication errors from multiple prescriptions?
- How might we design healthcare technology that feels simple and accessible?
- How might we improve medication adherence without overwhelming users?
- How might we create a healthcare app suitable for Saudi users and families?

### 2.3 Ideas Generated

| Idea | Description | Status |
|------|-------------|--------|
| **Smart Medication Management App** | Helps elderly manage medications and reminders |  **Selected** |
| AI Study Planner | Organizes study schedules and assignments |  Rejected |
| Local Event Discovery Platform | Shows nearby activities and events |  Rejected |

---

## 3. Idea Evaluation

### 3.1 Evaluation Criteria

| Criteria | Description | Score Range |
|----------|-------------|-------------|
| **Feasibility** | Ability to complete MVP within timeline/resources | 1-5 |
| **Potential Impact** | Degree to which solution addresses real-world problem | 1-5 |
| **Technical Alignment** | Match between project requirements and team skills | 1-5 |
| **Innovation** | Originality and uniqueness of the idea | 1-5 |
| **Scalability** | Potential for future expansion and features | 1-5 |
| **User Demand** | Likelihood users would benefit from solution | 1-5 |

### 3.2 Evaluation Matrix

| Criteria | Medication App | Study Planner | Event Platform |
|----------|:-------------:|:-------------:|:--------------:|
| Feasibility | 4 | 5 | 3 |
| Potential Impact | 5 | 3 | 3 |
| Technical Alignment | 5 | 4 | 3 |
| Innovation | 4 | 3 | 3 |
| Scalability | 5 | 4 | 4 |
| User Demand | 5 | 4 | 3 |
| **Total** | **28/30** | **23/30** | **19/30** |

### 3.3 Ranking

| Rank | Idea | Score |
|:----:|------|:-----:|
|  | **Smart Medication Management App** | **28/30** |
|  | AI Study Planner | 23/30 |
|  | Local Event Discovery Platform | 19/30 |

---

## 4. Final Decision & MVP Refinement

### 4.1 MVP Selection

After final discussion and voting, the team officially selected:

> **Smart Medication Management App for Elderly Patients** as the final MVP concept.

**Rationale:**
-  Highest evaluation scores
-  Real-world healthcare impact
-  Alignment with team skills
-  Clear and achievable MVP scope
-  Future expansion opportunities

### 4.2 Problem Statement

Many elderly patients struggle with medication management due to:

- Multiple prescriptions from different hospitals/clinics
- Forgetting medication schedules
- Difficulty organizing daily doses
- Risk of medication duplication or conflicts
- Lack of a centralized medication management system

**These challenges lead to:**
- Missed doses
- Incorrect medication usage
- Health complications
- Reduced treatment effectiveness

### 4.3 Target Audience

| User Type | Description |
|-----------|-------------|
| **Primary** | Elderly patients needing assistance with daily medication schedules |
| **Secondary** | Family members, caregivers, healthcare providers (future expansion) |

### 4.4 Core MVP Features

| Feature | Description |
|---------|-------------|
| **Medication Management** | Add, view, edit, delete medications with dosage and schedule |
| **Reminder Notifications** | Scheduled alerts for medication times, missed dose notifications |
| **Daily Dashboard** | Overview of today's medications and completion tracking |
| **Adherence Tracking** | Track taken vs. missed doses with percentage |
| **Arabic-First UI** | Large buttons, readable text, simple navigation |

### 4.5 Expected Outcomes

**User Benefits:**
- Improved medication adherence
- Reduced missed doses
- Easier prescription organization
- Better daily medication tracking

**Technical Outcomes:**
- Successful healthcare application implementation
- Frontend/backend integration experience
- Accessible user interface design

---

## 5. Risk Assessment

### 5.1 Risk Assessment Table

| Risk | Probability | Impact | Mitigation Strategy |
|------|:-----------:|:------:|---------------------|
| Team may lack experience with some technologies | Medium | Medium | Allocate learning time, share tutorials |
| Delays due to limited project timeline | High | High | Focus on core MVP features, clear task schedule |
| Notification reminders may not work consistently | Medium | High | Prioritize testing, implement stable reminder functionality |
| Difficulty designing interfaces for elderly users | High | High | Use simple layouts, large fonts, usability testing |
| Miscommunication between team members | Medium | Medium | Regular meetings, clear communication channels |
| Scope expansion beyond MVP requirements | Medium | High | Define in-scope/out-of-scope features from start |
| Competitors in medication reminder space | High | High | Differentiate through dependent management and elderly-first design |
| Elderly users may lack basic technology literacy | High | High | Provide onboarding tutorial, printed user guide |

---

## 6. Project Timeline

### 6.1 Project Phases

| Stage | Duration | Activities | Key Deliverables |
|-------|----------|------------|------------------|
| **Stage 1:** Idea Development | Week 1-2 | Team formation, brainstorming, research, idea evaluation | MVP idea, documentation |
| **Stage 2:** Project Charter | Week 3-4 | Define scope, objectives, stakeholders, risks | Project Charter document |
| **Stage 3:** Technical Documentation | Week 5-6 | System requirements, UML diagrams, database design | Technical documentation |
| **Stage 4:** MVP Development | Week 7-10 | Frontend/backend development, testing, bug fixing | Functional MVP prototype |
| **Stage 5:** Project Closure | Week 11-12 | Presentation, report submission, reflection | Final presentation |

### 6.2 Key Milestones

| Milestone | Expected Completion |
|-----------|---------------------|
| Team Formation Completed | End of Week 1 |
| MVP Idea Approved | End of Week 2 |
| Project Charter Finalized | End of Week 4 |
| Technical Documentation Completed | End of Week 6 |
| MVP Core Features Implemented | End of Week 9 |
| Final Testing Completed | Week 11 |
| Final Presentation and Submission | Week 12 |

---

## 7. Code Management Strategy

### 7.1 Branching Strategy (Gitflow)

```bash
main          # Stable releases
├── dev       # Main development
│   ├── feature/add-medication    # Individual features
│   ├── feature/reminder-system
│   └── feature/auth-implementation
├── hotfix/critical-bug    # Urgent fixes
└── release/v1.0.0         # Release preparation

7.2 Feature Branch Lifecycle
Step	Action	Command
1	Create branch from dev	git checkout -b feature/description dev
2	Develop feature with tests	Write code + tests
3	Push changes	git push origin feature/description
4	Open PR to dev	Via GitHub
5	Peer review and approval	Code review
6	Merge PR after CI passes	git merge --no-ff feature/description
7	Delete branch	git branch -d feature/description
7.3 Commit Message Convention
bash
# Format
<type>(<scope>): <description>

# Types
feat:     New feature
fix:      Bug fix
docs:     Documentation update
style:    Formatting changes
refactor: Code improvement without behavior change
test:     Add or update tests
chore:    Build and tool updates
perf:     Performance improvement
ci:       Continuous integration

# Examples
feat(medications): add medication CRUD operations
fix(reminders): fix notification timing issue
docs(api): update authentication endpoints documentation
7.4 Merge Requirements
done Requirements:

done All tests pass (Unit + Widget + Integration)

done Peer code review (2 approvals for large features)

done CI passes (GitHub Actions)

done Documentation updated

done 70% minimum test coverage

done Accessibility verification passed

7.5 Versioning (SemVer)
bash
MAJOR.MINOR.PATCH
   │     │     │
   │     │     └─── Bug fixes (backward compatible)
   │     └───────── New features (backward compatible)
   └─────────────── Breaking changes (not backward compatible)
8. Quality Assurance Strategy
8.1 Testing Types
Test Type	Description	Tool
Unit Tests	Test individual functions	Jest, flutter test
Widget Tests	Test UI components	flutter test
Integration Tests	Test component interaction	Supertest, flutter_driver
Performance Tests	Test speed and responsiveness	Flutter Profiler
Accessibility Tests	Test usability for elderly	TalkBack, VoiceOver
API Tests	Test full API endpoints	Postman, Newman
8.2 Coverage Requirements
done 70% minimum coverage for core logic

done 90% coverage for authentication functions

done 80% coverage for healthcare business logic

 All tests must pass before merging

8.3 CI/CD Pipeline
yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run test
      - run: npm run test:coverage

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter analyze
8.4 Rollback Strategy
In case of critical bug in production:

bash
# 1. Isolate the bug in a hotfix branch
git checkout main
git checkout -b hotfix/critical-bug

# 2. Fix the bug
# (Edit code)

# 3. Commit with proper classification
git commit -m "hotfix: fix critical bug in reminder system"

# 4. Merge to main
git checkout main
git merge --no-ff hotfix/critical-bug

# 5. Deploy update
npm run deploy

# 6. Cherry-pick fix to dev
git checkout dev
git cherry-pick <commit-hash>

# 7. Delete hotfix branch
git branch -d hotfix/critical-bug
8.5 QA Summary Checklist
Phase	Activity	Tool	Frequency
Development	Local testing	Android/iOS Emulator	Every feature
Development	Unit testing	flutter test	Every feature
Review	Code review	GitHub PRs	Every PR
Review	CI checks	GitHub Actions	Every PR
Integration	Manual testing	Emulator/Device	Every sprint
Pre-Release	Beta testing	Firebase/TestFlight	Before release
Release	Performance testing	Flutter Profiler	Every release
Release	Accessibility testing	TalkBack/VoiceOver	Every release
Post-Release	Bug tracking	GitHub Issues	Continuous
9. Test Results
9.1 Test Summary
bash
  PASS  tests/auth.test.js
  PASS  tests/interactions.test.js
  PASS  tests/offlineAuth.test.js

Test Suites: 3 passed, 3 total
Tests:       9 passed, 9 total
Time:        2.301 s
9.2 Detailed Test Results
Test File	Tests	Result	Time
auth.test.js	3	 PASS	0.8s
interactions.test.js	3	 PASS	0.9s
offlineAuth.test.js	3	 PASS	0.6s
9.3 Database Migrations
bash
done Connecting to database...
done Running SQL migrations...
done Resetting public schema...
done Applying migration: 001_create_enums.sql
done Applying migration: 002_create_tables.sql
done Applying migration: 003_create_indexes.sql
done Applying migration: 004_create_triggers.sql
done Applying migration: 005_seed_medicines.sql
done Applying migration: 006_seed_drug_interactions.sql
done Applying migration: 007_update_user_type_enum.sql
done Applying migration: 008_create_dependents_table.sql
done Applying migration: 009_add_dependent_to_medications.sql
done Applying migration: 010_add_medication_schedule_fields.sql
done SQL migrations completed successfully.
9.4 Environment Status
bash
Production Environment: http://localhost:56417/
APK Available: [QR Code]
Database: Connected 
All Tests: 9/9 Passing 
10. References
Resource	Description	Link
GitHub Flow	Official GitHub workflow guide	https://docs.github.com/en/get-started/quickstart/github-flow
Conventional Commits	Commit message specification	https://www.conventionalcommits.org/
GitHub Actions	CI/CD pipeline reference	https://docs.github.com/en/actions
Flutter Testing	Official Flutter testing guide	https://flutter.dev/docs/testing
Dart Style Guide	Dart coding conventions	https://dart.dev/guides/language/effective-dart
Firebase App Distribution	Android beta testing platform	https://firebase.google.com/products/app-distribution
TestFlight	Apple's beta testing platform	https://developer.apple.com/testflight/
Flutter Accessibility	Accessibility guidelines	https://flutter.dev/docs/development/accessibility
Semantic Versioning	Versioning specification	https://semver.org/
11. Conclusion
The idea development process allowed the team to move from broad brainstorming into a clearly defined and feasible MVP concept. Through research, structured evaluation, and collaborative decision-making, the team selected a healthcare solution with strong practical value and future potential.

The completion of Stage 1 established:
done A cohesive team structure with defined roles

done A refined MVP concept with clear scope

done Clear project direction and objectives

done A strong foundation for future planning and development stages

Quick Reference Card
Item	Details
Project	Smart Medication Management System - Dawai
MVP Score	28/30
Team Size	4 Members
Timeline	12 Weeks
Tech Stack	Flutter, Node.js, PostgreSQL
Tests	9/9 Passing
Key Features
done Medication CRUD Operations

done Reminder Notifications

done Adherence Tracking

done  Arabic-First UI

done  Elderly-Friendly Design

Status
 Stage 1 Complete

 MVP Concept Approved

 Technical Documentation Ready

 Ready for Stage 2

 Document Version History
Version	Date	Author	Changes
1.0	2026-06-28	Team Dawai	Initial document creation
1.1	2026-06-28	Team Dawai	Added Feature Branch Lifecycle Policy
1.2	2026-06-28	Team Dawai	Added Environment Configuration Management
1.3	2026-06-28	Team Dawai	Added Accessibility Testing
1.4	2026-06-28	Team Dawai	Added Performance Testing
1.5	2026-06-28	Team Dawai	Added Rollback Strategy
  Final Notes
Prepared by: Team Dawai
Date: 2026-06-28
Repository: [GitHub Repository Link]

Note: This document is the official Phase 1 Report for the Smart Medication Management System project. All team members have reviewed and approved its contents.

End of Document 

