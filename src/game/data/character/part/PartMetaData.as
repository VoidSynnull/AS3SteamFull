package game.data.character.part
{
	import ash.core.Component;
	
	import game.data.StateData;
	import game.data.character.LookAspectData;
	import game.data.specialAbility.SpecialAbilityData;
	import flash.utils.Dictionary;

	public class PartMetaData
	{	
		public function PartMetaData()
		{
			
		}

		/**
		 * set any parts outside of this one that should be hidden. 
		 * The full part will be hidden unless an instanceName is specified.
		 */
		public var hiddenParts:Vector.<String>;		// vector of part ids		
		
		/**
		 * set any colors that this part needs to be dynamic.
		 * This can be used by other parts to get this parts color information for coloring themselves.
		 */  
		public var colorAspects:Vector.<ColorAspectData>; // of ColorAspectDatas
		
		/**
		 * retrieve colors from other parts to be applied to the part's colors.  
		 * The id refers to the part that the color shold be retrieved from, to specifiy a specific color within a aprt use colorableId.  
		 * The value bewteen part tags refers to the color that the retrieved color will define.
		 * If colorable is not defined the first color within that part will ne used.
		 * If no color value defined, then the retrieved color willl apply itself to all colors.
		 */
		public var retrieveColors:Vector.<ColorByPartData>;
		
		/**
		 * applies colors to other parts.
		 * The color will apply to all colorable clips within the part unless an instanceName (to target a specific movieclip) 
		 * or colorableId (to target all clips inside a 'colorable' tag with that id) is specified.
		 */
		public var applyColors:Vector.<ColorByPartData>; 
		
		/**
		 * set any clips within this part that can be colored. 
		 * Specifying a clip without an instanceName will cause this entire part to be colorable.
		 * Allowable colors can optionally be set within the clip tags.  
		 * If the color is derived from another parts color, that part id can optionally be added in a 'sourcePartId' attribute. 
		 * An optional 'sourceColorableId' attribute can be added as well which specifies the color tag to use from the source part.
		 */
		public var colorables:Vector.<ColorableData>;
		
		/**
		 * state associated with part
		 */  
		public var state:StateData;
		
		/**
		 * data regarding other part's state that state's value should be applied.
		 */
		public var applyStates:Vector.<StateByPartData>; 
		
		/**
		 * NOT IMPLEMENTED
		 * set any parts outside of this one that should be changed to a new part.
		 */
		public var changeParts:Vector.<LookAspectData>;	//  vector of LookAspectData holding part id and value
		
		/**
		 * Component classes that should be added to the part
		 */
		public var components:Vector.<Component>;

		/**
		 * specify where this should reside in relation to other parts.  
		 * Can also specify 'top' or 'bottom' without an id to set the layer above or below all others.
		 */
		public var layer:LayerData;
		
		/**
		 * set an instance name of any clips that should match the direction (x scale) of the character (default is right).
		 * The tags within will set the frame labels to switch to, if no tags are specified will default to frame 1 = right, frame 2 = left
		 */
		public var direction:DirectionData;
		
		public var ignoreTimelines:Boolean = false;
		public var convertAllTimelines:Boolean = false;
		public var ignoreBitmap:Boolean = false;
		
		public var id:String;						// id that specifies the part, specific within each part category
		public var pendingId:String;				// the id that is currently loading, but has not been assigned yet
		public var partId:String;					// part id (e.g. shirt, hand1, mouth, facial, etc.)
		public var asset:String;					// name of asset to use, defaults to id if not specified
		public var gender:String = BOTH;			// if a gender is not specified, defaults to both
		
		public var costumizable:Boolean = true;		// If this part can be put on in the costumizer.
		public var notPrintable:Boolean = false;	// If this part can be put on printable products.
		public var membersOnly:Boolean = false;		// If this part is only wearable by members.
		public var sponsor:Boolean = false;			// If this is a sponsored part.
		public var special:SpecialAbilityData;		// If the part has a special ability attached to it
		
		public var campaignID:Number;		// sponsored items can be linked to the campaign id
		public var island:String;			// if part has functionality that should only work on an island, will disable the action when not on spcified island.
		
		
		public static const BOTH:String = "";
		public static const NONE:String = "none";
		
		/**
		 * attachments of other parts
		 */
		public var attachments:Dictionary;

		public function reset():void
		{
			id = "";
			pendingId = "";
			asset = "";
			gender = BOTH;
			costumizable = true;
			notPrintable = false;
			membersOnly = false;
			sponsor = false;
			campaignID = NaN;
			//island = "";
			
			if ( hiddenParts )		{ hiddenParts.length = 0; }
			if ( colorAspects )		{ colorAspects.length = 0; }
			if ( retrieveColors )	{ retrieveColors.length = 0; }
			if ( applyColors )		{ applyColors.length = 0; }
			if ( colorables )		{ colorables.length = 0; }
			if ( changeParts )		{ changeParts.length = 0; }
			if ( applyStates )		{ applyStates.length = 0; }
			layer = null;
			state = null;
			direction = null;
		}

		/*
		public function clone():PartMetaData
		{
			var data:PartMetaData = new PartMetaData();
			
			data.id = this.id
			data.asset = this.asset;
			data.gender = this.gender;
			data.costumizable = this.costumizable;
			data.notPrintable = this.notPrintable;
			data.membersOnly = this.membersOnly;
			data.sponsor = false;
			data.campaignID = NaN;
			data.island = "";
			
			data.hiddenParts = this.hiddenParts;
			data.colorAspects = this.colorAspects;
			data.retrieveColors = this.retrieveColors;
			data.applyColors = this.applyColors;
			data.colorables = this.colorables;
			data.changeParts = this.changeParts;
			data.effects = this.effects;
			data.actions = this.actions;
			data.layer = this.layer;
			data.direction = this.direction;

			return null;
		}
		*/
	}
}