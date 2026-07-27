const fs = require('fs');
const filePath = 'c:/Users/janab/Portfolio_Project/frontend/lib/views/dashboard/home_screen.dart';

let content = fs.readFileSync(filePath, 'utf8');
const org = content;

console.log('BEFORE:');
console.log('  <<<<<<<:', (content.match(/<<<<<<</g) || []).length);
console.log('  =======:', (content.match(/=======/g) || []).length);
console.log('  >>>>>>>:', (content.match(/>>>>>>>/g) || []).length);

// Step 1: Fix the corrupted _weekdayNameFromDate method
const weekdayRegex = /String _weekdayNameFromDate\(DateTime date\) \{[\s\S]*?return names\[weekday - 1\];\s*\}/;
const correctWeekday = `String _weekdayNameFromDate(DateTime date) {
    final weekday = date.weekday;
    const names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return names[weekday - 1];
  }`;
content = content.replace(weekdayRegex, correctWeekday);

console.log('\nAfter fixing weekdayName:');
console.log('  <<<<<<<:', (content.match(/<<<<<<</g) || []).length);
console.log('  =======:', (content.match(/=======/g) || []).length);
console.log('  >>>>>>>:', (content.match(/>>>>>>>/g) || []).length);

// Step 2: Replace all standard merge conflict blocks one by one
let iterations = 0;
let prevCount = content.match(/<<<<<<</g) ? content.match(/<<<<<<</g).length : 0;

while (content.includes('<<<<<<< Updated upstream') || content.includes('=======')) {
  iterations++;
  if (iterations > 50) break;
  
  // Replace one conflict block at a time - keep the stashed version
  const newContent = content.replace(
    /<<<<<<< Updated upstream[\s\S]*?=======\n([\s\S]*?)>>>>>>> Stashed changes/,
    (match, stashed) => stashed.trimEnd()
  );
  
  if (newContent === content) break;
  content = newContent;
  
  const currCount = (content.match(/<<<<<<</g) || []).length;
  if (currCount === prevCount) {
    // Try alternative pattern with \r\n
    const newContent2 = content.replace(
      /<<<<<<< Updated upstream\r\n([\s\S]*?)=======\r\n([\s\S]*?)>>>>>>> Stashed changes/,
      (match, upstream, stashed) => stashed
    );
    if (newContent2 !== content) {
      content = newContent2;
      continue;
    }
    break;
  }
  prevCount = currCount;
}

console.log('\nAfter merge conflict fix:');
console.log('  <<<<<<<:', (content.match(/<<<<<<</g) || []).length);
console.log('  =======:', (content.match(/=======/g) || []).length);
console.log('  >>>>>>>:', (content.match(/>>>>>>>/g) || []).length);

// Step 3: Handle any remaining orphaned markers
// Remove any remaining conflict lines
content = content.replace(/^<<<<<<< .*$/gm, '');
content = content.replace(/^=======$/gm, '');
content = content.replace(/^>>>>>>> .*$/gm, '');

console.log('\nAfter cleanup:');
console.log('  <<<<<<<:', (content.match(/<<<<<<</g) || []).length);
console.log('  =======:', (content.match(/=======/g) || []).length);
console.log('  >>>>>>>:', (content.match(/>>>>>>>/g) || []).length);

if (content !== org) {
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('\nFile saved!');
} else {
  console.log('\nNo changes needed.');
}

