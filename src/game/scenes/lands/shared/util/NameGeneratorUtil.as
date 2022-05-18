package game.scenes.lands.shared.util
{
	public class NameGeneratorUtil
	{
		static private var syllableStarts:Array = ["b", "d", "g", "k", "p", "t", "ch", "f", "s", "sh", "th", "v", "z", "j", "m", "n", "l", "r", "w", "y", "h"];
		static private var vowels:Array = ["a", "e", "i", "o", "u", "ai", "au", "ea", "ee", "oa", "ou", "oo"];
		static private var syllableEnds:Array = ["l", "s", "n", "r", "m"];
		static private var wordEnds:Array = ["b", "d", "g", "k", "ck", "p", "t", "ch", "f", "s", "sh", "ss", "th", "m", "n", "l", "ll", "r", "h", "x"];
		static private var forbiddenWords:Array = ["anal","anus","arse","ass","ballsack","balls","bastard","bitch","biatch","bloody","blowjob","bollock","bollok","boner","boob","bugger","bum","butt","buttplug","clitoris","cock","coon","crap","cunt","damn","dick","dildo","dyke","fag","feck","fellate","fellatio","felching","fuck","flange","hell","homo","jerk","jizz","knobend","labia","muff","nigger","nigga","penis","piss","poop","prick","pube","pussy","queer","scrotum","sex","shit","slut","smegma","spunk","tit","tosser","turd","twat","vagina","wank","whore"];
		
		public function NameGeneratorUtil()
		{
			
		}
		
		static public function generatePlanetName():String {
			var nameString:String = "";
			var numWords:uint = Math.ceil(Math.random()*2);
			for (var i:uint=0; i<numWords; i++) {
				var curWord:String = "";
				var numSyllables:uint = Math.ceil(Math.random()*3);
				for (var j:uint=0; j<numSyllables; j++) {
					//always start with consonant if not beginning of word, and usually at beginning too
					if (j > 0 || Math.random() > 0.2) {
						curWord += getRandomPart(syllableStarts);
					}
					curWord += getRandomPart(vowels);
					//optional end consonant
					if (Math.random() > 0.5) {
						//if ending word choose from wordEnds
						if (j == numSyllables - 1) {
							curWord += getRandomPart(wordEnds);
						}
						else {
							curWord += getRandomPart(syllableEnds);
						}
					}
				}
				
				curWord = checkForbidden(curWord);
				nameString += capWord(curWord);
				if (i < numWords - 1) {
					nameString += " ";
				}
			}
			return nameString;
		}
		
		static private function getRandomPart(array:Array):String {
			var part:String = array[Math.floor(Math.random()*array.length)];
			return part;
		}
		
		static private function capWord(word:String):String {
			var cap:String = word.substr(0,1);
			cap = cap.toUpperCase() + word.slice(1);
			return cap;
		}
		
		static private function checkForbidden(word:String):String {
			var newWord:String = word;
			for (var w:uint=0; w<forbiddenWords.length; w++) {
				if (word == forbiddenWords[w]) {
					newWord = "dom";
				}
			}
			return newWord;
		}
	}
}