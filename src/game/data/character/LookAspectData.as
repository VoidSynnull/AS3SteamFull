package game.data.character
{
	public class LookAspectData
	{	
		/**
		 * set any parts outside of this one that should be changed to a new part.
		 * @param	name
		 * @param	value
		 * @param	isPermanent
		 */
		public function LookAspectData( id:String = null, value:* = null )
		{
			this.id = id;
			this.value = value;
		}

		public var id : String;		// skin type, includes parts ( mouth, shirt ), colors ( skinColor, hairColor),and states ( squint )
		public var value:*;			// Skin component that owns this SkinData
	
		public function duplicate():LookAspectData
		{
			var newLookAspectData:LookAspectData = new LookAspectData();
			newLookAspectData.value = this.value;
			newLookAspectData.id = this.id;
			return newLookAspectData;
		}
		
		public function isEqual( lookAspect:LookAspectData ):Boolean
		{
			return ( lookAspect.id == this.id && lookAspect.value == this.value );
		}
		
	}
}