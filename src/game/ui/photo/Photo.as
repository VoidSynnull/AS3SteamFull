package game.ui.photo
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.UIView;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.DrawLimb;
	import game.components.entity.character.Rig;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class Photo extends UIView
	{
		private const CHARACTER_PORTRAIT:String = "characterPortrait";
		
		private var charGroup:CharacterGroup;
		private var charsLoaded:uint = 0;
		private var characters:uint = 0;
		
		public var lookConverter:LookConverter;
		public var characterLoadded:Signal;
		
		public function Photo(container:DisplayObjectContainer=null)
		{
			characterLoadded = new Signal(Entity, Boolean);
			lookConverter = new LookConverter();
			super(container);
		}
		
		public function configData(asset:String, prefix:String):void
		{
			groupPrefix = prefix;
			screenAsset = asset;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
		// createst a character that gets positioned into a predetermined pose
		public function addCharacterPose(container:DisplayObjectContainer, lookData:LookData, onComplete:Function =  null, limbsDrawnOn:Boolean = false):void
		{
			if(container.name.indexOf( "pose" ) == -1)
			{
				trace("Photo :: did not pass in the proper container");
				return;
			}
			
			var poseData:CharacterPoseData = new CharacterPoseData(container, limbsDrawnOn);
			
			if(poseData.eyeState != null)
				lookData.setValue(SkinUtils.EYE_STATE, poseData.eyeState);
			if(poseData.mouthState != null)
				lookData.setValue(SkinUtils.MOUTH, poseData.mouthState);
			
			addCharacterPortrait(container, lookData, Command.create(setUpCharacterForPhoto, poseData, onComplete),"left");
		}
		
		// creates a simplified character entity from the lookData and keeps track of how many were requested to be made
		private function addCharacterPortrait(container:DisplayObjectContainer, lookData:LookData, onComplete:Function = null, direction:String = "right", scale:Number = 1, position:Point = null):void
		{
			if(charGroup == null)
			{
				charGroup = new CharacterGroup();
				charGroup.setupGroup(this, this.container);
				characters = 0;
				charsLoaded = 0;
			}
			
			++characters;
			var char:Entity = charGroup.createDummy(CHARACTER_PORTRAIT+characters,lookData, direction,"" ,container,null, onCharacterLoaded,true, scale,CharacterCreator.TYPE_PORTRAIT, position );
			
			if(onComplete != null)
				characterLoadded.addOnce(onComplete);
		}
		
		//checks if all characters have been loaded and passes the character off to be positioned
		private function onCharacterLoaded(char:Entity):void
		{
			char.remove(Sleep);
			ToolTipCreator.removeFromEntity( char );
			++charsLoaded;
			
			var allCharsLoaded:Boolean = false;
			if(charsLoaded >= characters)
				allCharsLoaded = true;
			
			var spatial:Spatial = char.get(Spatial);
			spatial.x = spatial.y = 0;
			
			characterLoadded.dispatch(char, allCharsLoaded);
		}
		// repositions the character based off the pose designed for the character
		private function setUpCharacterForPhoto(char:Entity, allCharactersLoaded:Boolean, poseData:CharacterPoseData, onComplete:Function):void
		{
			CharUtils.poseCharacter(char, poseData);
			
			onComplete(char, allCharactersLoaded);
		}
		
		public function getPlayerLook():LookData
		{
			return lookConverter.lookDataFromPlayerLook(shellApi.profileManager.active.look);
		}
	}
}