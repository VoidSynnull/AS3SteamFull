package engine.creators
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Component;
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.group.DisplayGroup;
	import engine.group.Group;
	
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;

	public final class EntityCreator
	{
		public function EntityCreator()
		{
			throw new Error("EntityCreator is a static class. Do not instantiate.");
		}
		
		public static function createEntities(xml:XML, group:Group):Vector.<Entity>
		{
			var entities:Vector.<Entity> = new Vector.<Entity>();
			var entitiesXML:XMLList = xml.children();
			
			for each(var entityXML:XML in entitiesXML)
			{
				entities.push(EntityCreator.createEntity(entityXML, group));
			}
			
			return entities;
		}
		
		public static function createDisplayEntity(container:DisplayObjectContainer, url:String, xml:XML, group:DisplayGroup, callback:Function = null):Entity
		{
			var entity:Entity = createEntity(xml, group);
			
			if(url == null)
			{
				url = xml.attribute("url");
			}
			
			EntityUtils.loadAndSetToDisplay(container, url, entity, group, callback, false);
			
			return(entity);
		}
		
		public static function createEntity(entityXML:XML, group:Group):Entity
		{
			var name:String = entityXML.name;
			var entity:Entity = group.getEntityById(name);
			
			if(!entity)
			{
				entity = new Entity(name);
				group.addEntity(entity);
			}
			
			EntityCreator.addComponents(entityXML, entity);
			EntityCreator.addSystems(entityXML, group);
			
			return entity;
		}
		
		public static function addComponents(xml:XML, entity:Entity):void
		{
			var components:XMLList = xml.children();
			
			for each(var componentXML:XML in components)
			{
				if(componentXML.name() == "component")
				{
					EntityCreator.addComponent(componentXML, entity);
				}
			}
		}
		
		public static function addSystems(xml:XML, group:Group):void
		{
			var systems:XMLList = xml.children();
			
			for each(var systemXML:XML in systems)
			{
				if(systemXML.name() == "system")
				{
					EntityCreator.addSystem(systemXML, group);
				}
			}
		}
		
		public static function addComponent(componentXML:XML, entity:Entity):void
		{
			var component:Component = EntityCreator.createComponent(componentXML);
			var className:String = ClassUtils.getNameByObject(component);
			var clazz:Class = ClassUtils.getClassByName(className);
			
			entity.add(component);
		}
		
		public static function addSystem(systemXML:XML, group:Group):void
		{
			var priority:int =  DataUtils.useNumber(systemXML.attribute("priority"), 0);
			var system:System = ObjectCreator.create(systemXML);
			
			// add the system...groupManager won't add duplicates, so no additional check is necessary.
			group.addSystem(system, priority);
		}
		
		public static function createComponents(xml:XML):Vector.<Component>
		{
			var components:Vector.<Component> = new Vector.<Component>();
			
			if(xml.components)
			{
				var componentsXML:XMLList = xml.components.children();
				for each(var componentXML:XML in componentsXML)
				{
					components.push(EntityCreator.createComponent(componentXML));
				}
			}
			
			return components;
		}
		
		public static function createComponent(componentXML:XML):Component
		{
			return ObjectCreator.create(componentXML);
		}
	}
}