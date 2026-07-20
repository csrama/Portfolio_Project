-- Migration 006: Drug-drug interaction reference table
-- IMPORTANT: This is a curated academic starter set of well-established,
-- textbook-level drug interactions. It is NOT clinically exhaustive and
-- must not be presented to end users as a substitute for pharmacist or
-- physician review. Intended for capstone/demo purposes.

-- 1. Add generic_name to medicines so brand-name rows can be linked to
--    the active ingredients used in the interactions table below.
ALTER TABLE medicines ADD COLUMN IF NOT EXISTS generic_name TEXT;
CREATE INDEX IF NOT EXISTS idx_medicines_generic_name ON medicines (generic_name);

-- 2. Interaction reference table (ingredient-level, not brand-level)

CREATE TABLE drug_interactions (
    id SERIAL PRIMARY KEY,
    ingredient_a TEXT NOT NULL,
    ingredient_b TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('minor','moderate','major','contraindicated')),

    description TEXT NOT NULL,
    description_ar TEXT NOT NULL,

    recommendation TEXT,
    recommendation_ar TEXT,

    CONSTRAINT ordered_pair CHECK (ingredient_a < ingredient_b)
);

CREATE INDEX idx_interactions_a ON drug_interactions (ingredient_a);
CREATE INDEX idx_interactions_b ON drug_interactions (ingredient_b);

-- 3. Curated interaction data
-- Format: LOWER(ingredient_a) < LOWER(ingredient_b) alphabetically
INSERT INTO drug_interactions (
ingredient_a,
ingredient_b,
severity,
description,
description_ar,
recommendation,
recommendation_ar
)
VALUES
('amiodarone', 'digoxin', 'major', 'Amiodarone increases digoxin blood levels, raising risk of digoxin toxicity.', 'Monitor digoxin levels; may require dose reduction.'),
('amiodarone', 'warfarin', 'major', 'Amiodarone potentiates warfarin, increasing bleeding risk.', 'Monitor INR closely; warfarin dose often needs reduction.'),
('aspirin', 'warfarin', 'major', 'Combined use significantly increases risk of bleeding.', 'Avoid combination unless specifically directed; monitor for bleeding signs.'),
('aspirin', 'methotrexate', 'major', 'Aspirin reduces methotrexate clearance, increasing toxicity risk.', 'Avoid combination, especially with high-dose methotrexate.'),
('atorvastatin', 'clarithromycin', 'major', 'Macrolide antibiotics inhibit statin metabolism, increasing risk of myopathy/rhabdomyolysis.', 'Consider temporary statin suspension during antibiotic course.'),
('atorvastatin', 'fluconazole', 'major', 'Antifungal inhibits statin metabolism, raising myopathy risk.', 'Monitor for muscle pain; consider dose adjustment.'),
('carbamazepine', 'warfarin', 'moderate', 'Carbamazepine induces liver enzymes, reducing warfarin effectiveness.', 'Monitor INR when starting or stopping carbamazepine.'),
('ciprofloxacin', 'theophylline', 'major', 'Ciprofloxacin inhibits theophylline metabolism, risking toxicity (seizures, arrhythmia).', 'Monitor theophylline levels; avoid combination if possible.'),
('ciprofloxacin', 'warfarin', 'major', 'Fluoroquinolones can increase INR and bleeding risk.', 'Monitor INR closely during and after antibiotic course.'),
('calcium carbonate', 'ciprofloxacin', 'moderate', 'Calcium binds fluoroquinolones, reducing antibiotic absorption.', 'Separate doses by at least 2 hours.'),
('calcium carbonate', 'levothyroxine', 'moderate', 'Calcium reduces levothyroxine absorption.', 'Separate doses by at least 4 hours.'),
('clopidogrel', 'omeprazole', 'moderate', 'Omeprazole inhibits activation of clopidogrel, reducing antiplatelet effect.', 'Consider alternative PPI (e.g. pantoprazole) or H2 blocker.'),
('digoxin', 'furosemide', 'major', 'Furosemide-induced potassium loss increases risk of digoxin toxicity.', 'Monitor potassium and digoxin levels regularly.'),
('digoxin', 'verapamil', 'major', 'Verapamil increases digoxin levels and both slow AV conduction, risking bradycardia.', 'Monitor heart rate and digoxin levels; dose adjustment often needed.'),
('doxycycline', 'ferrous sulfate', 'moderate', 'Iron binds tetracyclines, reducing antibiotic absorption.', 'Separate doses by at least 2-3 hours.'),
('fluconazole', 'warfarin', 'major', 'Fluconazole inhibits warfarin metabolism, increasing bleeding risk.', 'Monitor INR closely; warfarin dose reduction often required.'),
('furosemide', 'gentamicin', 'major', 'Combination increases risk of ototoxicity and nephrotoxicity.', 'Monitor renal function and hearing; avoid prolonged combined use.'),
('glibenclamide', 'propranolol', 'moderate', 'Beta blockers can mask symptoms of hypoglycemia caused by sulfonylureas.', 'Monitor blood glucose closely; consider cardioselective beta blocker.'),
('ibuprofen', 'lisinopril', 'moderate', 'NSAIDs reduce the antihypertensive and renal-protective effects of ACE inhibitors, and may impair kidney function.', 'Use lowest effective NSAID dose; monitor blood pressure and renal function.'),
('ibuprofen', 'warfarin', 'major', 'NSAIDs increase bleeding risk when combined with warfarin.', 'Avoid combination; consider acetaminophen for pain relief.'),
('furosemide', 'ibuprofen', 'moderate', 'NSAIDs can reduce the diuretic effect of furosemide and impair renal function.', 'Monitor blood pressure, renal function, and fluid status.'),
('insulin', 'propranolol', 'moderate', 'Beta blockers can mask hypoglycemia symptoms (tremor, tachycardia) in insulin-treated patients.', 'Educate patient on non-adrenergic hypoglycemia signs (sweating, confusion).'),
('lisinopril', 'potassium chloride', 'major', 'ACE inhibitors reduce potassium excretion; combined with supplements this can cause dangerous hyperkalemia.', 'Monitor serum potassium regularly; avoid unnecessary supplementation.'),
('lisinopril', 'spironolactone', 'major', 'Both drugs raise potassium levels, risking severe hyperkalemia.', 'Monitor potassium closely; combination requires careful dose titration.'),
('lisinopril', 'losartan', 'major', 'Dual blockade of the renin-angiotensin system increases risk of hyperkalemia and renal impairment with little added benefit.', 'Avoid combining ACE inhibitors and ARBs unless specifically directed by a specialist.'),
('ibuprofen', 'lithium', 'major', 'NSAIDs reduce renal lithium clearance, raising lithium levels toward toxicity.', 'Monitor lithium levels; avoid regular NSAID use if possible.'),
('lisinopril', 'lithium', 'major', 'ACE inhibitors reduce lithium excretion, increasing toxicity risk.', 'Monitor lithium levels closely after starting or adjusting ACE inhibitor.'),
('furosemide', 'metformin', 'minor', 'Diuretics can affect blood glucose control and renal function relevant to metformin safety.', 'Monitor renal function and glucose control periodically.'),
('methotrexate', 'trimethoprim-sulfamethoxazole', 'major', 'Combination increases risk of bone marrow suppression.', 'Avoid combination; if unavoidable, monitor blood counts closely.'),
('metronidazole', 'warfarin', 'major', 'Metronidazole inhibits warfarin metabolism, increasing bleeding risk.', 'Monitor INR closely during and after treatment.'),
('levothyroxine', 'omeprazole', 'moderate', 'Reduced stomach acid from PPIs can decrease levothyroxine absorption.', 'Monitor thyroid function; consider separating doses.'),
('phenytoin', 'warfarin', 'moderate', 'Interaction is variable and can either increase or decrease INR.', 'Monitor INR closely when starting, stopping, or adjusting phenytoin.'),
('rifampin', 'warfarin', 'major', 'Rifampin strongly induces liver enzymes, markedly reducing warfarin effect.', 'Monitor INR closely; significant warfarin dose increase often needed.'),
('ibuprofen', 'sertraline', 'moderate', 'SSRIs combined with NSAIDs increase risk of gastrointestinal bleeding.', 'Consider gastroprotection (e.g. PPI) if combination is necessary.'),
('sertraline', 'tramadol', 'major', 'Combination increases risk of serotonin syndrome.', 'Avoid combination if possible; monitor for agitation, tremor, fever.'),
('isosorbide mononitrate', 'sildenafil', 'contraindicated', 'Combination can cause severe, life-threatening hypotension.', 'Absolute contraindication - do not combine under any circumstances.'),
('clarithromycin', 'simvastatin', 'major', 'Macrolide antibiotics inhibit statin metabolism, increasing risk of myopathy/rhabdomyolysis.', 'Consider temporary statin suspension during antibiotic course.'),
('diltiazem', 'simvastatin', 'moderate', 'Diltiazem inhibits statin metabolism, raising myopathy risk at higher statin doses.', 'Limit statin dose or use an alternative statin.'),
('phenelzine', 'tramadol', 'contraindicated', 'MAOIs combined with tramadol can cause life-threatening serotonin syndrome.', 'Absolute contraindication - do not combine; allow washout period between use.'),
('trimethoprim-sulfamethoxazole', 'warfarin', 'major', 'This antibiotic combination markedly increases INR and bleeding risk.', 'Monitor INR closely; dose adjustment usually required.'),
('metformin', 'prednisone', 'moderate', 'Corticosteroids can raise blood glucose, reducing metformin effectiveness.', 'Monitor blood glucose more closely when starting/stopping steroids.')
;
