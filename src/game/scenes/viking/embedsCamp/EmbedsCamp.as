package game.scenes.viking.embedsCamp
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.sound.SoundModifier;
	import game.managers.ads.AdManager;
	import game.scene.template.ItemGroup;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.shared.popups.MapPopup;
	import game.systems.motion.ProximitySystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.utils.AdUtils;
	
	import org.osflash.signals.Signal;
	
	public class EmbedsCamp extends VikingScene
	{
		private var proximityEntity:Entity;
		private var proximity:Proximity;
		private var tent:Entity;
		private var sleep:Entity;
		private var showSleep:Boolean = false;
		private var embed:Entity;
		
		private var tentClick:Entity;
		private var tentClickInteraction:Interaction;
		
		public function EmbedsCamp()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/embedsCamp/";
			
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
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			embed = this.getEntityById("embed");
			
			var adManager:AdManager = shellApi.adManager as AdManager;
			var noAd:Boolean = AdUtils.noAds(this);
			if(noAd)
				setupMapDoor();
			
			if(this.shellApi.checkEvent( _events.OCTAVIAN_RAN_AWAY )){
				var clip:MovieClip = _hitContainer["proximityEntity"];
				clip.visible = false;
				showSleep = true;
				this.removeEntity(embed);
				tentClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["tentClick"]), this);
				tentClick.remove(Timeline);
				tentClickInteraction = tentClick.get(Interaction);
				tentClickInteraction.downNative.add( Command.create( clickTent ));
				tentClick.get(Display).alpha = 0;
			}else{
				setupProximityEntity();
				showSleep = false;
				_hitContainer["feet"].visible = false;
				_hitContainer["tentClick"].visible = false;
				CharUtils.setAnim(embed, Sit, false);
			}
			
			setupSleep();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "lose_mind" ) {
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, sayFoolLine, true));
				
			}else if( event == "return_pan" ) {
				super.shellApi.camera.target = player.get(Spatial);
				SceneUtil.lockInput(this, false);
				Dialog(player.get(Dialog)).sayById("scary");
			}
		}
		
		private function clickTent(event:Event):void {
			Dialog(player.get(Dialog)).sayById("snoozeville");
		}
		
		private function setupSleep():void {
			var clip:MovieClip = _hitContainer["sleep"];
			if(showSleep){
				sleep = EntityUtils.createSpatialEntity(this, clip);
				BitmapTimelineCreator.convertToBitmapTimeline(sleep, clip);
				sleep.add(new Id("sleep"));
				Timeline(sleep.get(Timeline)).play();
				
				//positional snoring sound
				var entity:Entity = new Entity();
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
				entity.add(audio);
				entity.add(new Spatial(1345, 802));
				entity.add(new AudioRange(500, 0, 1, Quad.easeIn));
				entity.add(new Id("soundSource"));
				super.addEntity(entity);
			} else {
				clip.visible = false;
			}
		}
		
		private function setupMapDoor():void	{
			var door:Entity = super.getEntityById("doorMap");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			interaction.click = new Signal();
			interaction.click.add(moveToDoor);			
		}
		
		private function setupProximityEntity():void
		{
			var clip:MovieClip = _hitContainer["proximityEntity"];
			proximityEntity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			proximityEntity.add(spatial);
			proximityEntity.add(new Display(clip));
			proximityEntity.get(Display).alpha = 0;
			
			super.addEntity(proximityEntity);
			
			this.addSystem(new ProximitySystem());
			
			proximity = new Proximity(1050, this.player.get(Spatial));
			this.proximityEntity.add(proximity);
			proximity.entered.addOnce(playerRunAway);
		}
		
		private function playerRunAway(entity:Entity=null):void {
			MotionUtils.zeroMotion(player);
			
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(.1, 1, runAway, true));
		}
		
		private function runAway():void {
			super.shellApi.camera.target = embed.get(Spatial);
			Dialog( embed.get( Dialog )).faceSpeaker = false;
			Dialog(this.getEntityById("embed").get(Dialog)).sayById("whosThere");
			CharUtils.moveToTarget(player, 1627, 862, false);
			
			
			//CharUtils.setAnim( embed, Alerted, false, 0, 0, true );
			CharUtils.setAnim( embed, Stand, false, 0, 0, true );
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, faceRight, true));
		}
		
		private function faceRight():void {
			CharUtils.setDirection(embed, true);
		}
		private function faceLeft():void {
			CharUtils.setDirection(embed, false);
		}
		
		private function sayFoolLine(entity:Entity=null):void {
			faceLeft();
			CharUtils.setDirection(super.player, false);
			Dialog(this.getEntityById("embed").get(Dialog)).allowOverwrite = true;
			Dialog(this.getEntityById("embed").get(Dialog)).sayById("foolMind");
			proximity.entered.addOnce(playerRunAway);
			CharUtils.setAnim( embed, Sit, false, 0, 0, true );
		}
		
		private function saySnoozeLine(...args):void {
			Dialog(this.player.get(Dialog)).sayById("snoozeville");
		}
		
		private function moveToDoor(door:Entity):void {
			var targX:Number = door.get(Spatial).x - 20;
			var targY:Number = door.get(Spatial).y;
			CharUtils.moveToTarget(player, targX, targY, false, openMap);
		}
		
		private function openMap(entity:Entity):void {
			var mapPopup:MapPopup = new MapPopup(overlayContainer);
			addChildGroup(mapPopup);
		}
	}
}