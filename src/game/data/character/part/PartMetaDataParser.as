package game.data.character.part
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import engine.creators.EntityCreator;
	
	import game.components.entity.character.part.FlipPart;
	import game.data.StateData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.util.DataUtils;
		
	public class PartMetaDataParser
	{
		public function PartMetaDataParser()
		{
			
		}
		
		public function parseMetaData( dataXml:XML, id:String):PartMetaData
		{
			var metaData:PartMetaData = new PartMetaData();
			
			// set to true if part should ignore timelines
			metaData.ignoreTimelines = DataUtils.getBoolean( dataXml.attribute("ignoreTimelines"));
			metaData.convertAllTimelines = DataUtils.getBoolean( dataXml.attribute("convertAllTimelines"));
			metaData.ignoreBitmap = DataUtils.getBoolean( dataXml.attribute("ignoreBitmap"));
			
			// TODO :: Would really prefer if id was included within xml, instead of having to get it from the file name
			if ( DataUtils.validString( id ) )
			{
				metaData.id = id;
			}
			else
			{
				trace( "Error :: PartMetaDataParser :: parseMetaData :: id was not specified.");
			}
			
			if ( dataXml.hasOwnProperty("type") )
			{
				metaData.partId = DataUtils.getString(dataXml.type)
			}
			else
			{
				metaData.partId = metaData.id;
				//trace( "Error :: PartMetaDataParser :: parseMetaData :: type is not specified.");
			}
			
			metaData.asset			= ( dataXml.hasOwnProperty("asset") ) ? DataUtils.getString(dataXml.asset) : metaData.id;
			// rlh: don't filter by gender unless bare chest, else keep default to BOTH
			if (id == "bare")
				metaData.gender 		= ( dataXml.hasOwnProperty("gender") ) ? DataUtils.getString(dataXml.gender) : "";
			metaData.costumizable 	= ( dataXml.hasOwnProperty("costumizable") ) ? DataUtils.getBoolean(dataXml.costumizable) : true;
			metaData.notPrintable 	= ( dataXml.hasOwnProperty("notPrintable") ) ? DataUtils.getBoolean(dataXml.notPrintable) : false;
			metaData.membersOnly 	= ( dataXml.hasOwnProperty("membersOnly") ) ? DataUtils.getBoolean(dataXml.membersOnly) : false;
			metaData.sponsor 		= ( dataXml.hasOwnProperty("sponsor") ) ? DataUtils.getBoolean(dataXml.sponsor) : false;
			metaData.campaignID 	= ( dataXml.hasOwnProperty("campaignID") ) ? DataUtils.getNumber(dataXml.campaignID) : NaN;
			metaData.island 		= ( dataXml.hasOwnProperty("island") ) ? DataUtils.getString(dataXml.island) : "";
			
			if ( dataXml.hasOwnProperty("hide") )
			{
				metaData.hiddenParts = parseHidden(dataXml.hide);
			}
			
			if ( dataXml.hasOwnProperty("colors") )
			{
				metaData.colorAspects = parseColors(dataXml.colors, metaData.partId, metaData.id );
			}
			
			if ( dataXml.hasOwnProperty("retrieveColors") )
			{
				metaData.retrieveColors = parseRetrieveColor(dataXml.retrieveColors);
			}

			if ( dataXml.hasOwnProperty("applyColors") )
			{
				metaData.applyColors = parseApplyColor(dataXml.applyColors);
			}
			
			if ( dataXml.hasOwnProperty("colorables") )
			{
				metaData.colorables = parseColorable(dataXml.colorables);
			}
			
			if ( dataXml.hasOwnProperty("state") )
			{
				metaData.state = new StateData();
				metaData.state.parse( XML(dataXml.state) );
			}
			
			if ( dataXml.hasOwnProperty("applyState") )
			{
				metaData.applyStates = parseApplyState( XML(dataXml.applyState) )
			}
			
			if ( dataXml.hasOwnProperty("components") )
			{
				metaData.components = EntityCreator.createComponents(dataXml);
				for each (var component:Component in metaData.components)
				{
					// if flipPart is used as component, then set metaData.convertAllTimelines to true
					if (component is FlipPart)
					{
						metaData.convertAllTimelines = true;
						metaData.ignoreTimelines = false;
					}
				}
			}

			// Special Ability
			if ( dataXml.hasOwnProperty("specialAbility") )
			{
				var specialData:SpecialAbilityData = new SpecialAbilityData();
				specialData.parse(dataXml.specialAbility[0]);
				metaData.special = specialData;
			}
			
			// rlh: attach parts to this part
			if ( dataXml.hasOwnProperty("attach") )
			{
				metaData.attachments = parseAttachments(dataXml.attach);
			}
			return metaData;
		}
		
		private function parseHidden(xml:XMLList):Vector.<String>
		{
			var partsXML:XMLList = xml.children();
			var parts:Vector.<String> = new Vector.<String>();
			
			for (var n:uint = 0; n < partsXML.length(); n++)
			{
				parts.push(DataUtils.getString(partsXML[n]));
			}
			
			return(parts);
		}
		
		private function parseAttachments(xml:XMLList):Dictionary
		{
			var attachmentsXML:XMLList = xml.children();
			var attachments:Dictionary = new Dictionary();			
			for (var n:uint = 0; n < attachmentsXML.length(); n++)
			{
				var node:XML = attachmentsXML[n];
				var partID:String = node.name();
				attachments[partID] = DataUtils.getString(node);
			}
			return(attachments);
		}
		
		//////////////////////////////////////////////////////////////////////////////
		//////////////////////////////// PARSE COLORS //////////////////////////////// 
		//////////////////////////////////////////////////////////////////////////////
		
		private function parseColors(xml:XMLList, partType:String, partId:String ):Vector.<ColorAspectData>
		{
			var colorsXML:XMLList = xml.children();
			var colorXML:XML;
			var colorAspects:Vector.<ColorAspectData> = new Vector.<ColorAspectData>();
			var skinPartId:SkinPartId = new SkinPartId( partType, partId );
			
			for (var n:uint = 0; n < colorsXML.length(); n++)
			{
				colorXML = colorsXML[n];
				// NEW : TODO :: This format needs to be applied to metadata xml
				colorAspects.push( new ColorAspectData( skinPartId, DataUtils.getString(colorXML.attribute("id")), DataUtils.getNumber(colorXML) ) );
			}
			
			return(colorAspects);
		}
		
		private function parseRetrieveColor(xml:XMLList):Vector.<ColorByPartData>
		{
			var retrieveList:XMLList = xml.children();
			var retrieveXML:XML;
			var retrieveColors:Vector.<ColorByPartData> = new Vector.<ColorByPartData>();
			var colorByPartData:ColorByPartData;

			for (var n:uint = 0; n < retrieveList.length(); n++)
			{
				retrieveXML = retrieveList[n];
				colorByPartData = new ColorByPartData();
				colorByPartData.partId = DataUtils.getString(retrieveXML.attribute("id"));
				colorByPartData.partColorId = DataUtils.getString(retrieveXML.attribute("partColor"));
				colorByPartData.colorId = DataUtils.getString(retrieveXML);
				retrieveColors.push(colorByPartData);
			}
			
			return(retrieveColors);
		}
		
		private function parseApplyColor(xml:XMLList):Vector.<ColorByPartData>
		{
			var applyColors:Vector.<ColorByPartData> = new Vector.<ColorByPartData>();
			var applyList:XMLList = xml.children();
			var applyXML:XML;

			var colorByPartData:ColorByPartData;
			var colorId:String;
			var partXML:XML;
			
			for (var n:uint = 0; n < applyList.length(); n++)
			{
				applyXML = applyList[n];
				colorId = DataUtils.getString(applyXML.attribute("id"));
				
				var partsXML:XMLList = applyXML.children();
				for (var i:uint = 0; i < partsXML.length(); i++)
				{
					partXML = partsXML[i];
					colorByPartData = new ColorByPartData();
					colorByPartData.colorId = colorId;
					colorByPartData.partId = DataUtils.getString(partXML.attribute("id"));
					colorByPartData.partColorId = DataUtils.getString(partXML);
					if( DataUtils.validString(colorId) && !DataUtils.validString(colorByPartData.partColorId) )
					{
						colorByPartData.partColorId = colorByPartData.colorId;
					}
					applyColors.push(colorByPartData);
				}
			}
			
			return(applyColors);
		}
		
		private function parseColorable(xml:XMLList):Vector.<ColorableData>
		{
			var colorablesXML:XMLList = xml.children();
			var colorableXML:XML;
			var colorables:Vector.<ColorableData> = new Vector.<ColorableData>();
			var colorableData:ColorableData;
			
			var clipsXML:XMLList;
			var clipXML:XML;
			
	
			var i:int;
			var j:int;
			for (i = 0; i < colorablesXML.length(); i++)
			{
				colorableXML = colorablesXML[i];
				colorableData = new ColorableData();
				colorableData.colorId = DataUtils.getString(colorableXML.attribute("id")); 
				
				// set darken if specified darken 
				colorableData.darken = DataUtils.getNumber(colorableXML.attribute("darken")); 
				
				clipsXML = colorableXML.children();
				for (j = 0; j < clipsXML.length(); j++)
				{
					clipXML = clipsXML[j];
					colorableData.instances.push( new InstanceData( DataUtils.getString(clipXML.attribute("instanceName"))));
				}
				
				colorables.push(colorableData);
			}
			
			return(colorables);
		}
		
		//////////////////////////////////////////////////////////////////////////////
		//////////////////////////////// PARSE STATES //////////////////////////////// 
		//////////////////////////////////////////////////////////////////////////////
				
		private function parseApplyState( xml:XML):Vector.<StateByPartData>
		{
			var applyStates:Vector.<StateByPartData> = new Vector.<StateByPartData>();
			stateId = DataUtils.getString(xml.attribute("id"));
		
			var stateByPartData:StateByPartData;
			var stateId:String;
			var partXML:XML;
			
			var partsXML:XMLList = xml.children();
			for (var i:uint = 0; i < partsXML.length(); i++)
			{
				partXML = partsXML[i];
				stateByPartData = new StateByPartData();
				stateByPartData.stateId = stateId;
				stateByPartData.partId = DataUtils.getString(partXML.attribute("id"));
				stateByPartData.partStateId = DataUtils.getString(partXML);
				if( DataUtils.validString(stateId) && !DataUtils.validString(stateByPartData.partStateId) )
				{
					stateByPartData.partStateId = stateByPartData.stateId;
				}
				applyStates.push(stateByPartData);
			}

			return(applyStates);
		}
	}
}