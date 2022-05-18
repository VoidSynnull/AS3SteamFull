package game.creators.entity
{
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	
	import game.components.entity.Parent;
	import game.components.entity.State;
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.SkinPart;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.character.part.ColorAspectData;
	import game.data.character.part.PartMetaDataParser;
	import game.util.DataUtils;
	import game.util.EntityUtils;

	public class SkinCreator
	{
		private var _metaDataParser:PartMetaDataParser;
		
		public function SkinCreator()
		{
			_metaDataParser = new PartMetaDataParser();
		}
		
		/**
		 * Creates a new Skin and the SkinPart components that make up the Skin.
		 * If the SkinPart corresponds to a Joint, SkinPart is added to entity owning Part.
		 * If SkinPart does not correspond to a Joint, SkinPart is added is added to a newly created entity.
		 * Color components are also added to entities if specified by the skin xml.
		 * @param	group
		 * @param	character
		 * @param	rig
		 * @param	skin xml
		 * @return
		 */
		public function create( group:Group, character:Entity, rig:Rig, xml:XML):Skin
		{	
			var assetPath:String = xml.attribute("assetPath");
			var dataPath:String = xml.attribute("dataPath");
			var skin:Skin = character.get(Skin);
			if( skin == null )	{ skin = new Skin(); }
			
			var skinPartsXML:XMLList;
			var skinPartXML:XML;
			var applyPartsXML:XMLList;
			
			var entity:Entity;
			var skinPart:SkinPart;
			var colorSet:ColorSet;
			var colorAspect:ColorAspectData;
			var state:State;
			var parent:Parent;
			var id:Id;
			var metaData:MetaPart;
			
			var i:uint;
			var j:uint;

			if ( xml.hasOwnProperty("skinParts")  )
			{
				skinPartsXML = XMLList(xml.skinParts).children();
				
				for (i = 0; i < skinPartsXML.length(); i++)
				{	
					skinPartXML = XML( skinPartsXML[i] );

					// create new SkinPart and define variables
					skinPart = new SkinPart();
					skinPart.id = DataUtils.getString( skinPartXML.attribute("id"));
					if ( skinPartXML.hasOwnProperty("value") )
					{
						if ( DataUtils.getBoolean( skinPartXML.value.attribute("numeric") ) )
						{
							skinPart.setValue( DataUtils.getNumber( skinPartXML.value ) );
						}
						else
						{
							skinPart.setValue( DataUtils.getString( skinPartXML.value ) );
						}
					}
					
					// get corresponding part entity, or create new entity
					if ( skinPartXML.hasOwnProperty("part") )
					{
						entity = rig.getPart( DataUtils.getString( skinPartXML.part ) );
						if( entity == null ) 	// if no entity exists, skip
						{
							continue;
						}
					}
					else
					{
						entity = new Entity();
		
						// add MetaPart
						metaData = new MetaPart( skinPart.id, skinPart.id, assetPath, dataPath );
						if ( skinPartXML.hasOwnProperty("metaData") )
						{
							metaData.nextData = _metaDataParser.parseMetaData( XML(skinPartXML.metaData), skinPart.id); 
							metaData.hasPart = false;
							
							// add State if specified 
							// NOTE :: Currently states are only associated with non-part skinParts ( gender, eyeState )
							if ( metaData.nextData.state )
							{
								state = new State();
								state.updateComplete.add( skin.partsMetaComplete );
								entity.add( state );
							}
						}
						entity.add( metaData );
	
						//add Parent relationship
						EntityUtils.addParentChild(entity, character);
						
						// add Id
						id = new Id();
						id.id = skinPart.id;
						entity.add(id);
				
						group.addEntity( entity );
					}
					//add SkinPart
					entity.add( skinPart );
					
					// add ColorSet if specified
					if ( skinPartXML.hasOwnProperty("colorSet") )
					{
						colorSet = parseColorSet( XML(skinPartXML.colorSet) );
						colorSet.updateComplete.add( skin.partsMetaComplete );
						entity.add( colorSet );
					}

					// add Skin
					entity.add( skin );
					
					// save reference to SkinPart containing Entity within Skin ( allows SkinParts to be updated via Skin )
					skin.addSkinPartEntity( entity, skinPart.id );
				}
			}
			character.add( skin );
			return skin;
		}
		
		public function parseColorSet( colorSetXml:XML ):ColorSet
		{
			var colorSet:ColorSet = new ColorSet();
			
			// check for darken
			if ( colorSetXml.hasOwnProperty("darken") )
			{
				colorSet.darkenPercent = DataUtils.getNumber( colorSetXml.darken );
				if ( isNaN( colorSet.darkenPercent ) )
				{
					colorSet.darkenPercent = SkinCreator.DARKEN_SKIN;
				}
			}
			return colorSet;
		}
		
		/**
		 * Get default LookData from skin XML. 
		 * @param xml
		 * @return 
		 */
		public function parseLookData( xml:XML):LookData
		{
			var lookData:LookData = new LookData();

			var skinPartsXML:XMLList;
			var skinPartXML:XML;
			var lookAspect:LookAspectData;
			var i:uint;

			if ( xml.hasOwnProperty("skinParts")  )
			{
				skinPartsXML = XMLList(xml.skinParts).children();
				
				for (i = 0; i < skinPartsXML.length(); i++)
				{	
					skinPartXML = XML( skinPartsXML[i] );

					if ( skinPartXML.hasOwnProperty("value") )
					{
						lookAspect = new LookAspectData();
						
						if ( DataUtils.getBoolean( skinPartXML.value.attribute("numeric") ) )
						{
							lookAspect.value = DataUtils.getNumber( skinPartXML.value );
						}
						else
						{
							lookAspect.value = DataUtils.getString( skinPartXML.value );
						}
						
						lookAspect.id = DataUtils.getString( skinPartXML.attribute("id"));
						
						lookData.applyAspect( lookAspect );
					}
				}
			}
					
			return lookData;
		}
		
		public static const DARKEN_SKIN:Number 	= .15;
		
		public static const CHANGE_COLOR:String = "changeColor";
		public static const CHANGE_STATE:String = "changeState";
		public static const CHANGE_ASSET:String = "changeAsset";
	}
}
