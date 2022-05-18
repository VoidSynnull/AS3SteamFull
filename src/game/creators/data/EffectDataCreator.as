package game.creators.data
{
	import flash.filters.BevelFilter;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;

	import fl.motion.ColorMatrix;

	import game.util.DataUtils;

	public class EffectDataCreator
	{
		/**
		 * Create filter based on XML.
		 * @param effectXML - format sample
			 <effect>
				 <name>glowFilter</name>
				 <blurX>4</blurX>
				 <blurY>4</blurY>
				 <color>0xFFFFFF</color>
				 <strength>3000</strength>
				 <quality>1</quality>
			 </effect>
		 * @param filterName
		 * @return
		 */
		public static function parseEffect( effectXML:XML, filterName:String = "" ):*
		{
			if( !DataUtils.validString(filterName) )
			{
				filterName = DataUtils.getString( effectXML.name );
			}

			var filter:*;
			if( DataUtils.validString( filterName ) )
			{
				var filterParams:Array;
				// check name to determine type of effect (filter or color adjustment)
				switch(filterName)
				{
					case "adjustColorFilter":
						var colourFilter:ColorMatrix = new ColorMatrix();
						var colourMatrix:ColorMatrixFilter;
						// TODO :: having verification here wouldn't hurt - bard
						colourFilter.adjustBrightness(Number(effectXML.brightness));
						colourFilter.adjustContrast(Number(effectXML.contrast));
						colourFilter.adjustSaturation(Number(effectXML.saturation));
						colourFilter.adjustHue(Number(effectXML.hue));
						colourMatrix= new ColorMatrixFilter(colourFilter);
						return colourMatrix;

					case "dropShadow":
						filter = new DropShadowFilter();
						filterParams = dropShadowParams;
						break;

					case "blur":
						filter = new BlurFilter();
						filterParams = blurParams;
						break;

					case "glowFilter":
						filter = new GlowFilter();
						filterParams = glowParams;
						break;

					case "bevelFilter":
						filter = new BevelFilter();
						filterParams = bevelParams;
						break;
					/*
					NOT SUPPORTED YET
					case "gradientGlow":
					filter = new DropShadowFilter();
					filterParams = dropShadowParams;
					break;
					case "gradientBevel":
					filter = new DropShadowFilter();
					filterParams = dropShadowParams;
					break;
					*/
					default :
						return null;
						break;
				}

				var properties:XMLList = effectXML.children();
				var propertyXML:XML;
				var propName : String;
				var propValue : *;
				// NOTE :: Assuming first xml Object was the effect name
				for(var i : uint = 1; i < properties.length(); i++)
				{
					propertyXML = properties[i];
					propName = propertyXML.name()
					if( propName == "name" )
					{
						// used name to define filter (really should of been an attribute)
						continue;
					}

					//determine if valid property for current filter
					if( filterParams.indexOf( propName ) != -1 )
					{
						if( propName == "type" )
						{
							filter[propName] = DataUtils.getString(propertyXML);
						}
						else if( propName == "knockout" || propName == "innerShadow" || propName == "hideObject" )
						{
							filter[propName] = DataUtils.getBoolean(propertyXML);
						}
						else
						{
							filter[propName] = DataUtils.getNumber(propertyXML);
						}
					}
				}
			}
			return filter;
		}

		private static const dropShadowParams:Array = 		["blurX","blurY","strength","quality","angle","distance","color","knockout","innerGlow","hideObject"];
		private static const blurParams:Array = 			["blurX","blurY","quality"];
		private static const glowParams:Array = 			["blurX","blurY","strength","quality","color","knockout","innerGlow"];
		private static const bevelParams:Array = 			["blurX","blurY","strength","quality","shadow","highlight","angle","distance","knockout","type"];
		//private static const gradientGlowParams:Array =		["blurX","blurY","strength","quality","angle","distance","knockout","type","gradient"];
		//private static const gradientBevelParams:Array = 	["blurX","blurY","strength","quality","angle","distance","knockout","type","gradient"];
		private static const adjustColorParams:Array = 		["brightness","contrast","saturation","hue"];
	}
}
