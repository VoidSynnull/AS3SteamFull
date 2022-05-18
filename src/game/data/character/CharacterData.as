package game.data.character
{
	import flash.geom.Point;
	
	import game.data.animation.AnimationSequence;
	import game.data.scene.labels.LabelData;

	/**
	 * ...
	 * @author Bard
	 */
	public class CharacterData
	{
		public var id:String;
		public var type:String;
		public var variant:String;
		public var dynamicParts:Boolean;
		public var bitmap:String;
		public var movieClip:String;
		public var randomSkin:Boolean;

		public var costumizable:Boolean = true;
		public var position:Point;
		public var range:Point;
		public var look:LookData;
		public var direction:String;
		public var faceSpeaker:Boolean;
		public var ignoreDepth:Boolean;
		public var scale:Number = NaN;
		public var lineThickness:Number = 0;
		public var noDarken:Boolean = false;
		public var animSequence:AnimationSequence;
		/** Scene event that the CharData corresponds to */
		public var event:String;
		public var proximity:Number = -1; //default is turned off
		/** Flag determining if a tool tip is created for character when character is created */
		public var addToolTip:Boolean = false;
		/** Data necessary for tooltip */
		public var label:LabelData;

		public var talkMouth:String;

		public function CharacterData():void
		{
			position = new Point();
		}

		public function init( id:String, position:Point = null, look:LookData = null, direction:String = "right", type:String = TYPE_NPC, event:String = "default" ):void
		{
			this.id = id;
			this.type = type;
			if( position) { this.position = position };
			if( look )	{ this.look = look }
			this.direction = direction;
			this.event = event;
		}

		public function fillData( charData:CharacterData ):void
		{
			position 		= ( position ) ?  position : charData.position;
			range 			= ( range ) ?  range : charData.range;
			direction 		= ( direction ) ?  direction : charData.direction;
			scale 			= ( scale ) ?  scale : charData.scale;
			ignoreDepth 	= ( ignoreDepth ) ?  ignoreDepth : charData.ignoreDepth;
			animSequence 	= ( animSequence ) ? animSequence : charData.animSequence;
			proximity 		= ( proximity ) ? proximity : charData.proximity;
			lineThickness 	= ( lineThickness ) ? lineThickness : charData.lineThickness;
			noDarken	 	= ( noDarken ) ? noDarken : charData.noDarken;

			if ( look )
			{
				look.fill(charData.look);
			}
			else
			{
				look = new LookData();
				look = charData.look;	// TODO :: does this need to be duplicated?
			}
		}

		public function duplicate():CharacterData
		{
			var charData:CharacterData = new CharacterData();
			charData.id = this.id;
			charData.type = this.type;
			charData.variant = this.variant;
			charData.dynamicParts = this.dynamicParts;
			if( this.bitmap ) { charData.bitmap = this.bitmap; }	// TODO :: likely need to clone
			charData.randomSkin = this.randomSkin;

			charData.costumizable = this.costumizable;
			if( this.position ) { charData.position = this.position.clone(); }
			if( this.range ) { charData.range = this.range.clone(); }
			if( this.look ) { charData.look = this.look.duplicate(); }
			charData.direction = this.direction;
			charData.faceSpeaker = this.faceSpeaker;
			charData.ignoreDepth = this.ignoreDepth;
			charData.scale = this.scale;
			charData.lineThickness = this.lineThickness;
			charData.noDarken = this.noDarken;
			if( this.animSequence ) { charData.animSequence = this.animSequence.duplicate(); }
			charData.event = this.event;
			charData.label = this.label;
			if( this.proximity ) { charData.proximity = this.proximity; }

			return charData;
		}


		public static const TYPE_NPC:String 	= "npc";
		public static const TYPE_PLAYER:String 	= "player";
		public static const TYPE_DUMMY:String 	= "dummy";

		public static const VARIANT_APE:String			= "ape";
		public static const VARIANT_CREATURE:String 	= "creature";
		public static const VARIANT_PET_BABYQUAD:String = "pet_babyquad";
		public static const VARIANT_HEAD:String 		= "head";
		public static const VARIANT_HUMAN:String 		= "human";
	}


}
