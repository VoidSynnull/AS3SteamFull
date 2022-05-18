package game.managers
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	
	import game.data.scene.TemplateGroupParser;
	import game.util.EntityUtils;

	public class TemplateManager
	{
		public function TemplateManager()
		{
		}
		
		public function init(group:DisplayGroup, xml:XML):void
		{
			_group = group;
			
			var parser:TemplateGroupParser = new TemplateGroupParser();
			_templateGroups = parser.parse(xml, _group.groupPrefix);
		}
		
		public function makeFromTemplates(templateId:String, container:DisplayObjectContainer = null, assetLoadedCallback:Function = null, processor:Function = null):Entity
		{
			var entity:Entity = new Entity();
			
			_group.addEntity(entity);
			
			applyTemplates(entity, templateId, container, assetLoadedCallback, processor);
					
			return(entity);
		}
		
		public function applyTemplates(entity:Entity, templateId:String, container:DisplayObjectContainer = null, assetLoadedCallback:Function = null, processor:Function = null):void
		{
			var templates:Vector.<String> = _templateGroups[templateId];
			var templateUrl:String;
			var templatesToLoad:Array = new Array();
			var loadedTemplates:Array = new Array();
			var nextTemplate:XML;
			var assetUrl:String;
			
			// make sure all templates are loaded
			for(var n:int = 0; n < templates.length; n++)
			{
				templateUrl = templates[n];
				nextTemplate = _group.getData(templateUrl, false, true);
				
				if(nextTemplate == null)
				{
					templatesToLoad.push(templateUrl);
				}
				else
				{
					loadedTemplates.push(nextTemplate);
					
					if(nextTemplate.hasOwnProperty("assetUrl"))
					{
						assetUrl = nextTemplate.assetUrl;
					}
				}
			}
			
			// if we are missing any templates, load them before processing.
			if(templatesToLoad.length > 0)
			{
				_group.loadFiles(templatesToLoad, true, true, templatesLoaded, entity, templateId, container, assetLoadedCallback, processor);
			}
			else
			{
				// adds both components and systems specified in this template.
				TemplateUtils.addFromTemplate(loadedTemplates, entity, _group, processor);
				
				// if any of the templates have a <assetUrl> tag load and set it to the entity's display
				if(container != null && assetUrl != null)
				{
					EntityUtils.loadAndSetToDisplay(container, assetUrl, entity, _group, assetLoadedCallback, false);
				}
				else
				{
					assetLoadedCallback(null, entity);
				}
			}
		}
		
		private function templatesLoaded(entity:Entity, templateId:String, container:DisplayObjectContainer = null, assetLoadedCallback:Function = null, processor:Function = null):void
		{
			applyTemplates(entity, templateId, container, assetLoadedCallback, processor);
		}
		
		private var _templateGroups:Dictionary;
		private var _group:DisplayGroup;
	}
}