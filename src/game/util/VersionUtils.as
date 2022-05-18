package game.util
{
	public class VersionUtils
	{
		/**
		 * Compares and returns the highest version number.
		 * @param version1 The first verion number.
		 * @param version2 The second verion number.
		 * @param numSections The number of sections to compare up to.
		 * @return The highest version number.
		 */
		public static function max(version1:String, version2:String, numSections:uint = uint.MAX_VALUE):String
		{
			var index:int = VersionUtils.compare(version1, version2, numSections);
			
			if(index > -1)
			{
				var section1:uint = 0;
				var section2:uint = 0;
				
				var sections1:Array = version1.split(".");
				var sections2:Array = version2.split(".");
				
				if(index < sections1.length)
				{
					section1 = sections1[index];
				}
				if(index < sections2.length)
				{
					section2 = sections2[index];
				}
				
				if(section1 > section2)
				{
					return version1;
				}
				else
				{
					return version2;
				}
			}
			//The versions are the same.
			return version1;
		}
		
		/**
		 * Compares and returns the lowest version number.
		 * @param version1 The first version number.
		 * @param version2 The second version number.
		 * @param numSections The number of sections to compare up to.
		 * @return The lowest version number.
		 */
		public static function min(version1:String, version2:String, numSections:uint = uint.MAX_VALUE):String
		{
			return version1 == VersionUtils.max(version1, version2, numSections) ? version2 : version1;
		}
		
		/**
		 * Checks to see if two version numbers are equal.
		 * @param version1 The first version number.
		 * @param version2 The second version number.
		 * @param numSections The number of sections to compare up to.
		 * @return True if the version numbers are equal, and false otherwise.
		 */
		public static function equals(version1:String, version2:String, numSections:uint = uint.MAX_VALUE):Boolean
		{
			return VersionUtils.compare(version1, version2, numSections) == -1;
		}
		
		/**
		 * Compares two version numbers and returns the index where they initially become different.
		 * @param version1 The first version number.
		 * @param version2 The second version number.
		 * @param numSections The number of sections to compare up to.
		 * <ul>
		 * <li>If numSections = 2, then we only check version1 = "[#.#].#.#" against version2 = "[#.#].#".</li>
		 * </ul>
		 * @return The section index where the versions begin to differ.
		 */
		public static function compare(version1:String, version2:String, numSections:uint = uint.MAX_VALUE):int
		{
			//Both exist, so compare them.
			if(version1 && version2)
			{
				//Split the version numbers into "#.#.#.#", or "major.minor.maintenance.build", plus any excessive sections.
				var sections1:Array = version1.split(".");
				var sections2:Array = version2.split(".");
				
				var length:uint = sections1.length;
				//Check the max sections of both versions. "1.0.0.1" is greater than "1.0.0" and differs at [3] in that case.
				length = Math.max(length, sections2.length);
				//Check the min sections we want/need to compare. We might have 3 sections, but only want to compare to 2.
				length = Math.min(length, numSections);
				
				for(var index:uint = 0; index < length; ++index)
				{
					//The section will cast to 0 if the index exceeds sections.length - 1. Section [3] in 1.0.0[.0] will cast to 0.
					var section1:uint = uint(sections1[index]);
					var section2:uint = uint(sections2[index]);
					if(section1 != section2)
					{
						return index;
					}
				}
				return -1;
			}
			//Both are null or empty Strings, so they are equal.
			else if(!version1 && !version2)
			{
				return -1;
			}
			//One of the versions is null, so technically they are different right at the start.
			return 0;
		}
		
		public static function between(version:String, min:String, max:String):Boolean
		{
			if(VersionUtils.equals(version, min))
			{
				return true;
			}
			if(VersionUtils.equals(version, max))
			{
				return true;
			}
			if(min && VersionUtils.min(version, min) == version)
			{
				return false;
			}
			if(max && VersionUtils.max(version, max) == version)
			{
				return false;
			}
			return true;
		}
		
		/**
		 * Returns the version's number at the given section from a version String.
		 * @param version A version number in the format of "#.#.#.#".
		 * @return The version's number at the given section, or 0 if the section doesn't exist.
		 */
		public static function getSection(version:String, section:uint):uint
		{
			if(version)
			{
				var sections:Array = version.split(".");
				if(sections.length >= section + 1)
				{
					return sections[section];
				}
			}
			return 0;
		}
		
		/**
		 * Returns the version's major number from a version String.
		 * @param version A version number in the format of "#.#.#.#".
		 * @return The version's major number.
		 */
		public static function getMajor(version:String):uint
		{
			return VersionUtils.getSection(version, 0);
		}
		
		/**
		 * Returns the version's minor number from a version String.
		 * @param version A version number in the format of "#.#.#.#".
		 * @return The version's minor number.
		 */
		public static function getMinor(version:String):uint
		{
			return VersionUtils.getSection(version, 1);
		}
		
		/**
		 * Returns the version's maintenance number from a version String.
		 * @param version A version number in the format of "#.#.#.#".
		 * @return The version's maintenance number.
		 */
		public static function getMaintenance(version:String):uint
		{
			return VersionUtils.getSection(version, 2);
		}
		
		/**
		 * Returns the version's build number from a version String.
		 * @param version A version number in the format of "#.#.#.#".
		 * @return The version's build number.
		 */
		public static function getBuild(version:String):uint
		{
			return VersionUtils.getSection(version, 3);
		}
		
		public static function toVersion(major:uint = 0, minor:uint = 0, maintenance:uint = 0, build:uint = 0):String
		{
			return major + "." + minor + "." + maintenance + "." + build;
		}
	}
}