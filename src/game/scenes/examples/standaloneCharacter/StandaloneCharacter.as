package game.scenes.examples.standaloneCharacter
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	
	public class StandaloneCharacter extends Scene
	{
		public function StandaloneCharacter()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/standaloneCharacter/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			// only need a list of npcs and the background asset for this scene.  Not using scene.xml as we don't need the camera here.
			super.loadFiles(["npcs.xml", "background.swf"]);
		}
				
		// all assets ready
		override public function loaded():void
		{
			// scale the background to stretch to the screensize.  We're not using a camera here, so manipulating the scene art is done manually.
			var background:MovieClip = super.groupContainer.addChild(super.getAsset("background.swf", true)) as MovieClip;
			background.width = super.shellApi.viewportWidth;
			background.height = super.shellApi.viewportHeight;
			
			// load the characters into the the groupContainer instead of the hitContainer since this isn't a platformer scene with camera layers.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupScene(this, super.groupContainer, super.getData("npcs.xml"), allCharactersLoaded, false);
		}
		
		protected function allCharactersLoaded():void
		{
			// This triggers the 'ready' signal in the superclass 'DisplayGroup' that shows this scene.
			super.loaded();
			
			var npc:Entity = super.getEntityById("npc");
			// center the npc
			Spatial(npc.get(Spatial)).x = super.shellApi.viewportWidth * .5;
			Spatial(npc.get(Spatial)).y = super.shellApi.viewportHeight * .5;
			
			// scale the npc.  This util will scale the character without effecting the direction their facing.
			CharUtils.setScale(npc, 1);
		}
	}
}