package game.managers
{
	import ash.core.Entity;
	
	import engine.creators.EntityCreator;
	import engine.group.Group;

	public class TemplateUtils
	{	
		public static function addFromTemplate(templates:Array, entity:Entity, group:Group, processor:Function = null):void
		{
			var xml:XML;
			
			for(var n:int = 0; n < templates.length; n++)
			{
				xml = templates[n];
				
				if(processor != null)
				{
					processor(xml);
				}
				
				EntityCreator.addComponents(xml, entity);
				EntityCreator.addSystems(xml, group);
			}
		}
		
		public static function addComponentsFromTemplate(templates:Array, entity:Entity, processor:Function = null):void
		{
			var xml:XML;
			
			for(var n:int = 0; n < templates.length; n++)
			{
				xml = templates[n];
				
				if(processor != null)
				{
					processor(xml);
				}
				
				EntityCreator.addComponents(xml, entity);
			}
		}
		
		public static function addSystemsFromTemplate(templates:Array, group:Group, processor:Function = null):void
		{
			var xml:XML;
			
			for(var n:int = 0; n < templates.length; n++)
			{
				xml = templates[n];
				
				if(processor != null)
				{
					processor(xml);
				}
				
				EntityCreator.addSystems(xml, group);
			}
		}
	}
}