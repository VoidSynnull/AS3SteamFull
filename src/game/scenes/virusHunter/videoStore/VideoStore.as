package game.scenes.virusHunter.videoStore
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Salute;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class VideoStore extends PlatformerGameScene
	{
		public function VideoStore()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/videoStore/";
			
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
			// add in TV Sounds
			
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.MUSIC_PATH + "vh_video_romantic_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
			//entity.add(new Display(super._hitContainer["tv1"]));
			entity.add(audio);
			entity.add(new Spatial(205, 282));
			entity.add(new AudioRange(500, .03, 1, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);

			entity = new Entity();
			audio = new Audio();
			audio.play(SoundManager.MUSIC_PATH + "vh_video_action_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
			//entity.add(new Display(super._hitContainer["tv2"]));
			entity.add(audio);
			entity.add(new Spatial(891, 282));
			entity.add(new AudioRange(380, .01, .5, Quad.easeIn));
			entity.add(new Id("soundSource2"));
			super.addEntity(entity);
			
			entity = new Entity();
			audio = new Audio();
			audio.play(SoundManager.MUSIC_PATH + "vh_video_strange_loop.mp3", true, [SoundModifier.POSITION, , SoundModifier.MUSIC])
			//entity.add(new Display(super._hitContainer["tv3"]));
			entity.add(audio);
			entity.add(new Spatial(1710, 282));
			entity.add(new AudioRange(660, .01, .75, Quad.easeIn));
			entity.add(new Id("soundSource3"));
			super.addEntity(entity);
			
			
			
			super.loaded();
			
			_virusEvents = new VirusHunterEvents();
			
			_backRoomDoor = super.getEntityById("door2");
			
			var videoStoreClerk:Entity = super.getEntityById("npc");
			super.convertToBitmapSprite(super._hitContainer["desk"], null, true);
			DisplayUtils.moveToOverUnder( super._hitContainer["desk"], Display(videoStoreClerk.get(Display)).displayObject );
			
			// swap depths with desk and NPC - to make him appear behind the desk
			//_hitContainer.swapChildren(Display(videoStoreClerk.get(Display)).displayObject, _hitContainer["desk"]);
			//super._hitContainer.setChildIndex(super._hitContainer["desk"], super._hitContainer.numChildren-1);
			super._hitContainer.setChildIndex(super.player.get(Display).displayObject, super._hitContainer.numChildren-1);
			
			/*if(super.shellApi.checkEvent("talkedToClerk") == false){
				var interaction:Interaction = InteractionCreator.addToEntity(videoStoreClerk, [InteractionCreator.DOWN]);
				interaction.down.add(clerkClicked);
			} else {
				super.shellApi.triggerEvent("ignoringYouOnClick");
			}*/
			
			// deny back door - until badge is shown
			if(super.shellApi.checkEvent(_virusEvents.USED_BADGE) == false){
				// save a reference to the original signal
				_savedBDSignal = SceneInteraction(_backRoomDoor.get(SceneInteraction)).reached;
				
				// create new signal with custom handler, so you don't change the original reference
				SceneInteraction(_backRoomDoor.get(SceneInteraction)).reached = new Signal();
				SceneInteraction(_backRoomDoor.get(SceneInteraction)).reached.add(reachedDoor);
			} else {
				// hide clerk
				//Display(videoStoreClerk.get(Display)).visible = false;
				super.removeEntity(videoStoreClerk);
				SceneInteraction(_backRoomDoor.get(SceneInteraction)).reached.add(shakeBeadDoor);
			}
			
			// popcorn
			_popcorn = TimelineUtils.convertClip(super._hitContainer["popCorn"], this);
			_popcorn.add(new Display(super._hitContainer["popCorn"]));
			_popcorn.add(new Spatial(super._hitContainer["popCorn"].x, super._hitContainer["popCorn"].y));
			var popcornInt:Interaction = InteractionCreator.addToEntity(_popcorn, [InteractionCreator.DOWN]);
			popcornInt.down.add(clickPopcorn);
			
			var tip:Entity = ToolTipCreator.create( ToolTipType.CLICK, super._hitContainer["popCorn"].x, super._hitContainer["popCorn"].y );
			EntityUtils.addParentChild( tip, _popcorn );
			this.addEntity( tip );
			
			for (var i:uint=1; i<=6; i++) {
				this["_beadString" + i] = TimelineUtils.convertClip(super._hitContainer["string" + i], this);
			}
			
			for (i=1; i<=3; i++) {
				this["_tv" + i] = TimelineUtils.convertAllClips(super._hitContainer["tv" + i], this["_tv" + i], this);
			}
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			//trace(super.getEntityById("npc").getAll());
			
			// if player is holding badge, override dialog
			if(super.shellApi.checkHasItem(_virusEvents.PDC_BADGE) && !super.shellApi.checkEvent(_virusEvents.USED_BADGE)){
				SceneInteraction(super.getEntityById("npc").get(SceneInteraction)).reached = new Signal();
				SceneInteraction(super.getEntityById("npc").get(SceneInteraction)).reached.add(clerkReached);
			}
		}
		
		private function clickPopcorn($entity):void{
			var timeline:Timeline = $entity.get(Timeline);
			timeline.paused = false;
			if(_popcornSound == null){
				_popcornSound = new Entity();
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "popcorn.mp3", false, [SoundModifier.POSITION, SoundModifier.MUSIC])
				//entity.add(new Display(super._hitContainer["tv1"]));
				_popcornSound.add(audio);
				_popcornSound.add(new Spatial(602, 423));
				_popcornSound.add(new AudioRange(500, .03, 1, Quad.easeIn));
				_popcornSound.add(new Id("soundSource"));
				super.addEntity(_popcornSound);
			} else {
				Audio(_popcornSound.get(Audio)).stop(SoundManager.EFFECTS_PATH + "popcorn.mp3");
				Audio(_popcornSound.get(Audio)).play(SoundManager.EFFECTS_PATH + "popcorn.mp3", false, [SoundModifier.POSITION, SoundModifier.MUSIC])
			}
		}
		
		private function shakeBeadDoor($interactor:Entity, $interacted:Entity):void{
			for (var i:uint=1; i<=6; i++) {
				Timeline(this["_beadString" + i].get(Timeline)).gotoAndPlay(13-i*2);
			}
		}
		
		private function reachedDoor($interactor:Entity, $interacted:Entity):void{
			/**
			 * Occurs if player tries to enter the door before showing the fake badge.
			 * @perma = true
			 */
			Dialog(super.getEntityById("npc").get(Dialog)).sayById("noEntry");
		}
		
		private function clerkClicked($entity:Entity):void{
			/**
			 * Occurs after player has talked to the clerk
			 * @perma = false
			 */
			
			//trace("clerk clicked!");
			
			if(super.shellApi.checkEvent("talkedToClerk") == false){
				//trace("talk to clerk!");
				//super.shellApi.triggerEvent("talkToClerk");
			}
		}
		
		private function clerkReached($entity1:Entity, $entity2:Entity):void{
			trace("clerk reached!");
			super.shellApi.triggerEvent(_virusEvents.SHOW_BADGE);
			//showBadge($entity1);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case _virusEvents.SHOW_BADGE:
					/**
					 * If the "used_badge" event isn't checked for completion, there will be a crash involving the
					 * showBadge() function trying to find the clerk when he's already been removed.
					 */
					if(this.shellApi.checkEvent(_virusEvents.USED_BADGE)) return;
					
					CharUtils.moveToTarget(super.player, 400, super.sceneData.bounds.bottom, false, showBadge);
					
					var backRoomDoor:Entity = super.getEntityById("door2");
					SceneInteraction(backRoomDoor.get(SceneInteraction)).reached = _savedBDSignal; // return original signal
					SceneInteraction(backRoomDoor.get(SceneInteraction)).reached.add(shakeBeadDoor);
					
					SceneUtil.lockInput(this, true);
					
					break;
				case _virusEvents.USED_BADGE:
					// clerk walks into next room
					var npc:Entity = super.getEntityById("npc");
					var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
					charGroup.addFSM( npc );
					Sleep(npc.get(Sleep)).ignoreOffscreenSleep = true;
					Sleep(npc.get(Sleep)).sleeping = false;
					
					//_hitContainer.swapChildren(Display(npc.get(Display)).displayObject, _hitContainer["desk"]);
					super._hitContainer.setChildIndex(npc.get(Display).displayObject, super._hitContainer.numChildren-1);
					
					CharUtils.moveToTarget(npc, 757, 525, false, npcReachedTarget);
					
					SceneUtil.lockInput(this, false);
					
					break;
			}
		}
		
		private function showBadge(e:Entity):void
		{
			Dialog(super.getEntityById("npc").get(Dialog)).sayById("seenBadge");
			// unlock back door
			CharUtils.setDirection(super.player, true);
			CharUtils.setAnim( super.player, Salute, false );
		}
		
		private function npcReachedTarget($entity:Entity):void{
			// dissapear video clerk
			Display($entity.get(Display)).visible = false;
			shakeBeadDoor(null, null);
			var backRoomDoor:Entity = super.getEntityById("door2");
			Audio(backRoomDoor.get(Audio)).playCurrentAction("doorOpened");
		}
		
		private var _popcornSound:Entity;
		private var _popcorn:Entity;
		private var _savedBDSignal:Signal;
		private var _virusEvents:VirusHunterEvents;
		private var _beadString1:Entity;
		private var _beadString2:Entity;
		private var _beadString3:Entity;
		private var _beadString4:Entity;
		private var _beadString5:Entity;
		private var _beadString6:Entity;
		private var _backRoomDoor:Entity;
		private var _tv1:Entity;
		private var _tv2:Entity;
		private var _tv3:Entity;
	}
}