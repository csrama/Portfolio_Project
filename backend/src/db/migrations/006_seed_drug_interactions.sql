-- 1. Add generic_name column to medicines if not exists
ALTER TABLE medicines ADD COLUMN IF NOT EXISTS generic_name TEXT;
CREATE INDEX IF NOT EXISTS idx_medicines_generic_name ON medicines (generic_name);

-- 2. Interaction reference table (without recommendation columns)
CREATE TABLE IF NOT EXISTS drug_interactions (
    id SERIAL PRIMARY KEY,
    ingredient_a TEXT NOT NULL,
    ingredient_b TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('minor','moderate','major','contraindicated')
    ),
    description TEXT NOT NULL,
    description_ar TEXT NOT NULL,
    
    CONSTRAINT ordered_pair CHECK (ingredient_a < ingredient_b)

);


CREATE INDEX IF NOT EXISTS idx_interactions_a ON drug_interactions (ingredient_a);
CREATE INDEX IF NOT EXISTS idx_interactions_b ON drug_interactions (ingredient_b);

-- 3. Curated interaction data
INSERT INTO drug_interactions (ingredient_a, ingredient_b, severity, description, description_ar) VALUES
('amiodarone', 'digoxin', 'major', 'Amiodarone increases digoxin blood levels, raising risk of digoxin toxicity.', ''),
('amiodarone', 'warfarin', 'major', 'Amiodarone potentiates warfarin, increasing bleeding risk.', ''),
('aspirin', 'warfarin', 'major', 'Combined use significantly increases risk of bleeding.', ''),
('aspirin', 'methotrexate', 'major', 'Aspirin reduces methotrexate clearance, increasing toxicity risk.', ''),
('atorvastatin', 'clarithromycin', 'major', 'Macrolide antibiotics inhibit statin metabolism, increasing risk of myopathy/rhabdomyolysis.', ''),
('atorvastatin', 'fluconazole', 'major', 'Antifungal inhibits statin metabolism, raising myopathy risk.', ''),
('carbamazepine', 'warfarin', 'moderate', 'Carbamazepine induces liver enzymes, reducing warfarin effectiveness.', ''),
('ciprofloxacin', 'theophylline', 'major', 'Ciprofloxacin inhibits theophylline metabolism, risking toxicity (seizures, arrhythmia).', ''),
('ciprofloxacin', 'warfarin', 'major', 'Fluoroquinolones can increase INR and bleeding risk.', ''),
('calcium carbonate', 'ciprofloxacin', 'moderate', 'Calcium binds fluoroquinolones, reducing antibiotic absorption.', ''),
('calcium carbonate', 'levothyroxine', 'moderate', 'Calcium reduces levothyroxine absorption.', ''),
('clopidogrel', 'omeprazole', 'moderate', 'Omeprazole inhibits activation of clopidogrel, reducing antiplatelet effect.', ''),
('digoxin', 'furosemide', 'major', 'Furosemide-induced potassium loss increases risk of digoxin toxicity.', ''),
('digoxin', 'verapamil', 'major', 'Verapamil increases digoxin levels and both slow AV conduction, risking bradycardia.', ''),
('doxycycline', 'ferrous sulfate', 'moderate', 'Iron binds tetracyclines, reducing antibiotic absorption.', ''),
('fluconazole', 'warfarin', 'major', 'Fluconazole inhibits warfarin metabolism, increasing bleeding risk.', ''),
('furosemide', 'gentamicin', 'major', 'Combination increases risk of ototoxicity and nephrotoxicity.', ''),
('glibenclamide', 'propranolol', 'moderate', 'Beta blockers can mask symptoms of hypoglycemia caused by sulfonylureas.', ''),
('ibuprofen', 'lisinopril', 'moderate', 'NSAIDs reduce the antihypertensive and renal-protective effects of ACE inhibitors, and may impair kidney function.', ''),
('ibuprofen', 'warfarin', 'major', 'NSAIDs increase bleeding risk when combined with warfarin.', ''),
('furosemide', 'ibuprofen', 'moderate', 'NSAIDs can reduce the diuretic effect of furosemide and impair renal function.', ''),
('insulin', 'propranolol', 'moderate', 'Beta blockers can mask hypoglycemia symptoms (tremor, tachycardia) in insulin-treated patients.', ''),
('lisinopril', 'potassium chloride', 'major', 'ACE inhibitors reduce potassium excretion; combined with supplements this can cause dangerous hyperkalemia.', ''),
('lisinopril', 'spironolactone', 'major', 'Both drugs raise potassium levels, risking severe hyperkalemia.', ''),
('lisinopril', 'losartan', 'major', 'Dual blockade of the renin-angiotensin system increases risk of hyperkalemia and renal impairment with little added benefit.', ''),
('ibuprofen', 'lithium', 'major', 'NSAIDs reduce renal lithium clearance, raising lithium levels toward toxicity.', ''),
('lisinopril', 'lithium', 'major', 'ACE inhibitors reduce lithium excretion, increasing toxicity risk.', ''),
('furosemide', 'metformin', 'minor', 'Diuretics can affect blood glucose control and renal function relevant to metformin safety.', ''),
('methotrexate', 'trimethoprim-sulfamethoxazole', 'major', 'Combination increases risk of bone marrow suppression.', ''),
('metronidazole', 'warfarin', 'major', 'Metronidazole inhibits warfarin metabolism, increasing bleeding risk.', ''),
('levothyroxine', 'omeprazole', 'moderate', 'Reduced stomach acid from PPIs can decrease levothyroxine absorption.', ''),
('phenytoin', 'warfarin', 'moderate', 'Interaction is variable and can either increase or decrease INR.', ''),
('rifampin', 'warfarin', 'major', 'Rifampin strongly induces liver enzymes, markedly reducing warfarin effect.', ''),
('ibuprofen', 'sertraline', 'moderate', 'SSRIs combined with NSAIDs increase risk of gastrointestinal bleeding.', ''),
('sertraline', 'tramadol', 'major', 'Combination increases risk of serotonin syndrome.', ''),
('isosorbide mononitrate', 'sildenafil', 'contraindicated', 'Combination can cause severe, life-threatening hypotension.', ''),
('clarithromycin', 'simvastatin', 'major', 'Macrolide antibiotics inhibit statin metabolism, increasing risk of myopathy/rhabdomyolysis.', ''),
('diltiazem', 'simvastatin', 'moderate', 'Diltiazem inhibits statin metabolism, raising myopathy risk at higher statin doses.', ''),
('phenelzine', 'tramadol', 'contraindicated', 'MAOIs combined with tramadol can cause life-threatening serotonin syndrome.', ''),
('trimethoprim-sulfamethoxazole', 'warfarin', 'major', 'This antibiotic combination markedly increases INR and bleeding risk.', ''),
('metformin', 'prednisone', 'moderate', 'Corticosteroids can raise blood glucose, reducing metformin effectiveness.', '');