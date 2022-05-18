package game.data.scene
{
	import flash.utils.Dictionary;
	import game.util.DataUtils;

	public class TemplateGroupParser
	{
		public function parse(xml:XML, groupPrefix:String = ""):Dictionary
		{
			var groups:Dictionary = new Dictionary();
			var templateGroups:XMLList = xml.children();
			var templates:XMLList;
			var id:String;
			var files:Vector.<String>;
			var nextGroup:XML;
			var nextFile:XML;
			
			for (var i:uint = 0; i < templateGroups.length(); i++)
			{
				nextGroup = templateGroups[i];
				templates = nextGroup.children();
				id = nextGroup.attribute("id");
				files = new Vector.<String>();
				
				for (var n:uint = 0; n < templates.length(); n++)
				{
					nextFile = templates[n];
					files.push(DataUtils.getString(nextFile.valueOf()));
				}
				
				groups[id] = files;
			}
			
			return(groups);
		}
	}
}