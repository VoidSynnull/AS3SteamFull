package game.data.character 
{

	/**
	 * ...
	 * @author Bard
	 */
	public class VariantData
	{
		public static const XML_PATH:String = "entity/character/variants/";

		public var variant:String;
		
		public var skinXmlPath:String;
		public var rigXmlPath:String;
		public var sizeXmlPath:String;
		public var springXmlPath:String;
		public var limbXmlPath:String;
		
		public var skinXml:XML;
		public var rigXml:XML;
		public var sizeXml:XML;
		public var springXml:XML;
		public var limbXml:XML;
		
		public var xmlLoaded:Boolean = false;
	}
}