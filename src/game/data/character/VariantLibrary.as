package game.data.character 
{
	import engine.ShellApi;
	import flash.utils.Dictionary;
	
	import engine.Manager;

	/**
	 * ...
	 * @author Bard
	 */
	public class VariantLibrary extends Manager
	{
		public function VariantLibrary() 
		{
			
		}
		
		/**
		 * Instantiate animation class, loads xml, and adds to Dictionary if not yet added.
		 * Animation classes are shared across all entities that use this system
		 * @param	animationClass
		 * @param	type
		 */
		public function add( variant:String ):void
		{
			if (!_variantDict[variant])
			{
				// create CharacterData
				var variantData:VariantData = createVariantData(variant);
				_variantDict[variant] = variantData;
				variantData.xmlLoaded = false
				
				// load xml
				shellApi.loadFiles( [ variantData.skinXmlPath, variantData.rigXmlPath, variantData.sizeXmlPath, variantData.springXmlPath, variantData.limbXmlPath ], onXMLLoaded, variantData );
			}
		}
		
		public function onXMLLoaded( variantData:VariantData ):void
		{
			if (!_variantDict[variantData.variant])
			{
				this._variantDict[variantData.variant] = variantData;
			}
			_variantDict[variantData.variant].rigXml 	= shellApi.getFile( variantData.rigXmlPath );
			_variantDict[variantData.variant].springXml = shellApi.getFile( variantData.springXmlPath );
			_variantDict[variantData.variant].sizeXml 	= shellApi.getFile( variantData.sizeXmlPath );
			_variantDict[variantData.variant].skinXml 	= shellApi.getFile( variantData.skinXmlPath );
			_variantDict[variantData.variant].limbXml 	= shellApi.getFile( variantData.limbXmlPath );
			
			_variantDict[variantData.variant].xmlLoaded = true;
		}
		
		public function getVariantData( variant:String ):VariantData
		{
			var variantData:VariantData = _variantDict[ variant ];
			
			if ( variantData )
			{
				if ( variantData.xmlLoaded )	// don't return until AnimationData has been created/loaded
				{
					return variantData;
				}
			}
			return null;
		}
		
		public function createVariantData( variant:String ):VariantData
		{
			var variantData:VariantData = new VariantData();
			variantData.variant = variant;
			variantData.rigXmlPath 		= shellApi.dataPrefix + VariantData.XML_PATH + variant + "/" + RIG_XML;
			variantData.springXmlPath 	= shellApi.dataPrefix + VariantData.XML_PATH + variant + "/" + SPRING_XML;
			variantData.sizeXmlPath 	= shellApi.dataPrefix + VariantData.XML_PATH + variant + "/" + SIZE_XML;
			variantData.skinXmlPath 	= shellApi.dataPrefix + VariantData.XML_PATH + variant + "/" + SKIN_XML;
			variantData.limbXmlPath 	= shellApi.dataPrefix + VariantData.XML_PATH + variant + "/" + LIMB_XML;
	
			return variantData;
		}

		public const RIG_XML:String 	= "rigDefault.xml";
		public const SPRING_XML:String 	= "springConfig.xml";
		public const SIZE_XML:String 	= "sizeDefault.xml";
		public const SKIN_XML:String 	= "skinDefault.xml";
		public const LIMB_XML:String 		= "drawLimbConfig.xml";
		
		private var _variantDict:Dictionary = new Dictionary(true);
	}
}