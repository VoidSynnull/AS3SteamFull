package game.scenes.examples.specialAbilityExample{
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.specialAbility.SpecialAbilityControl;
	import game.creators.ui.ButtonCreator;
	import game.data.specialAbility.SpecialAbilityData;
	import game.scene.template.PlatformerGameScene;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.SkinUtils;
	
	
	public class SpecialAbilityExample extends PlatformerGameScene
	{
		public function SpecialAbilityExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/specialAbilityExample/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			super.addSystem( new SpecialAbilityControlSystem() );
			super.addSystem( new TimelineControlSystem() );
			super.addSystem( new TimelineClipSystem() );
			buttonData = new Dictionary();
			//loadSpecialAbilityXML();
			entityTarget = getEntityById("npc3");
			
			var items:Array = ["3050"];
				
			for(var i:Number = 0; i < items.length; i++)
			{
				shellApi.getItem( items[i], "store" );
			}
				
				
				
			//Add an ability manually
			//_specialData = new SpecialAbilityData(ThrowCurd);
			//_specialData.triggerable = true;
			//CharUtils.addSpecialAbility( super.player, _specialData, true );
		}
		
		// Load the XML sheet holding all of the Special Abilities
		private function loadSpecialAbilityXML():void
		{	
			//specialAbilityXML = super.getData("specialAbilities.xml");
			specialAbilityXML = super.getData("specialAbilitiesAnimations.xml");
			
			var specials:XMLList = new XMLList(specialAbilityXML.specialAbility);
			trace("number of specials: " + specials.length());
			
			for (var i:int = 0; i < specials.length(); i++)
			{
				var currBtnXML:XML = specials[i];
				var label:String = currBtnXML.@id;
				var xPos:Number = buttonStartX + (Math.floor(i / 5) * 205);
				var yPos:Number = buttonStartY + ((i % 5) * 40);
				//createButton((i+1) + ": " + label, currBtnXML, xPos, yPos );
				createButton(label, currBtnXML, xPos, yPos );
			}
			
			// Make the trigger button
			createTriggerButton();
		}
		
		private function createButton(label:String, xmlData:XML, x:Number, y:Number):void
		{
			super.loadFile("button.swf", buttonLoadComplete, label, xmlData, x, y);
		}
		
		private function buttonLoadComplete(button:MovieClip, label:String, xmlData:XML, x:Number, y:Number):void
		{	
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 16, 0xD5E1FF);
			super._hitContainer.addChild(button);	
			var newButton:Entity = ButtonCreator.createButtonEntity( button, this, addSpecialAbility );
			ButtonCreator.addLabel( button, label, labelFormat, ButtonCreator.ORIENT_TOPLEFT );
			newButton.add(new Spatial(x, y));
			super.addEntity(newButton);
			
			// save the button data for interaction
			buttonData[newButton] = new Object();
			buttonData[newButton].xml = xmlData;
		}
		
		private function createTriggerButton():void
		{
			super.loadFile("button.swf", triggerButtonLoadComplete);
		}
		
		private function triggerButtonLoadComplete(button:MovieClip):void
		{	
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			super._hitContainer.addChild(button);	
			var newButton:Entity = ButtonCreator.createButtonEntity( button, this, callTrigger );
			ButtonCreator.addLabel( button, "Trigger Special", labelFormat, ButtonCreator.ORIENT_TOPLEFT );
			newButton.add(new Spatial(40, 680));
			super.addEntity(newButton);
		}

		
		/**
		 * EXAMPLE 1 : Adding a SpecialAbility
		 * 
		 * @param	button
		 */
		private function addSpecialAbility( button:Entity ):void
		{
			var xmlData:XML = buttonData[button].xml;

			//_specialData = new SpecialAbilityData();
			//_specialData.parse(xmlData);
			//_specialData.triggerable = true;
			//Let's add the part to see it in action, or remove old one
			if (xmlData.part.length() > 0)
			{
				trace(xmlData.part != null);
				//SkinUtils.getSkinPart( super.shellApi.player, String(xmlData.part.@type) ).setValue( String(xmlData.part) );
				SkinUtils.setSkinPart(super.shellApi.player, String(xmlData.part.@type), String(xmlData.part), true, partLoadComplete);
			} else {
				SkinUtils.getSkinPart( super.shellApi.player, "item" ).setValue( "1" );
				//CharUtils.addSpecialAbility( super.player, _specialData, true );
			}
		}
		
		private function partLoadComplete():void
		{
			trace("part loaded");
			//CharUtils.addSpecialAbility( super.player, _specialData, true );
		}
		
		
		private function removeSpecialAbility():void
		{
			var specialControl:SpecialAbilityControl = super.player.get( SpecialAbilityControl ) as SpecialAbilityControl;
			if ( specialControl )
			{
				specialControl.removeSpecialByType( _specialData.type );
			}
		}
				
		private function callTrigger( button:Entity ):void
		{
			CharUtils.triggerSpecialAbility( super.player );
		}
		
		private var _specialData:SpecialAbilityData;
		private var specialAbilityXML:XML;
		private var buttonData:Dictionary;
		private var buttonStartX:Number = 40;
		private var buttonStartY:Number = 460;
		
		public var entityTarget:Entity;
	}
}