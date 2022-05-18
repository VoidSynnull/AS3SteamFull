package game.scenes.shrink.silvaOfficeShrunk02
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Grief;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.sunriseStreet.Systems.EarthquakeSystem;
	import game.scenes.backlot.sunriseStreet.components.Earthquake;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.silvaOfficeShrunk01.SilvaOfficeShrunk01;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class SilvaOfficeShrunk02 extends PlatformerGameScene
	{
		public function SilvaOfficeShrunk02()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/silvaOfficeShrunk02/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		private var cj:Entity;
		private var silva:Entity;
		private var cameraShake:Entity;
		private var gunTarget:Point;
		private var shrink:ShrinkEvents;
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			addSystem(new ThresholdSystem());
			setUpSilva();
			setUpNPCs();
			setUpGun();
			Dialog(player.get(Dialog)).sayById("in the office");
			shellApi.completeEvent(shrink.IN_SILVAS_OFFICE);
			shellApi.removeEvent(shrink.IN_CAR);
		}
		
		private function setUpSilva():void
		{
			var clip:MovieClip = _hitContainer["largeShadow"];
			BitmapUtils.convertContainer(clip);
			var shadow:Entity = EntityUtils.createSpatialEntity(this, clip,_hitContainer);
			shadow.add(new Id("shadow")).remove(Sleep);
		}
		
		private function setUpNPCs():void
		{
			var chars:Array = ["char1", "char2", "player"];
			var setDialog:Array = ["convo", "there you are", "in the office"];
			
			cj = getEntityById("char1");
			CharUtils.setDirection(cj, true);
			SceneInteraction(cj.get(SceneInteraction)).reached.add(talkingToCj);
			Interaction(cj.get(Interaction)).click.add(talkNormal);
			
			silva = getEntityById("char2");
			silva.remove(Sleep);
			
			for(var i:int = 0; i < chars.length; i++)
			{
				var dialog:Dialog = getEntityById(chars[i]).get(Dialog);
				dialog.start.add(startedTalking);
				dialog.complete.add(finishedTalking);
				dialog.setCurrentById(setDialog[i]);
			}
			
			var threshold:Threshold = new Threshold("x", "<",cj);
			threshold.entered.add(talkToCj);
			player.add(threshold);
		}
		
		private function talkNormal(entity:Entity):void
		{
			SceneInteraction(entity.get(SceneInteraction)).offsetX = 100;
		}
		
		private function talkToCj():void
		{
			var interaction:SceneInteraction = cj.get(SceneInteraction);
			interaction.offsetX = -100;
			interaction.activated = true;
			SceneUtil.lockInput(this);
		}
		
		private function talkingToCj(...args):void
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function setUpGun():void
		{
			var clip:MovieClip = _hitContainer["gun"];
			BitmapUtils.convertContainer(clip);
			var gun:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			gun.add(new Id("gun"));
			
			gunTarget = new Point(140, 325);
		}
		
		private function startedTalking(dialog:DialogData):void
		{
			if(dialog.id == "convoquestion2")
				SceneUtil.lockInput(this);
		}
		
		private function finishedTalking(dialog:DialogData):void
		{
			if(dialog.id == "convoanswer2")
				earthQuake();
			if(dialog.id == "being watched")
				gotYouNow();
			if(dialog.id == "there you are")
				pointShrinkRay();
			if(dialog.id == "ill make millions")
				panic();
			if(dialog.id == "run")
				runForIt();
		}
		
		private function earthQuake():void
		{
			addSystem(new EarthquakeSystem());
			cameraShake = EntityUtils.createSpatialEntity(this,new MovieClip(), _hitContainer);
			cameraShake.add(new Earthquake(player.get(Spatial),new Point(25,50), 1,45, new Point(0, -110)));
			SceneUtil.setCameraTarget(this, cameraShake);
			TweenUtils.entityTo(cameraShake, Earthquake,1,{severity: 0, ease:Linear.easeOut, onComplete:enterSilva});
		}
		
		private function enterSilva():void
		{
			SceneUtil.setCameraTarget(this, player);
			removeEntity(cameraShake);
			Dialog(player.get(Dialog)).sayById("being watched");
			var target:MovieClip = _hitContainer["panSilva"];
			TweenUtils.entityTo(getEntityById("shadow"), Spatial, 2, {x:target.x, y:target.y, ease:Linear.easeNone});
		}
		
		private function gotYouNow():void
		{
			SceneUtil.setCameraTarget(this, getEntityById("shadow"));
			Dialog(silva.get(Dialog)).sayById("there you are");
		}
		
		private function pointShrinkRay():void
		{
			Dialog(silva.get(Dialog)).sayById("ill make millions");
			var target:Point = new Point(player.get(Spatial).x, player.get(Spatial).y);
			var gunRotation:Number = Math.atan2(target.y - gunTarget.y, target.x - gunTarget.x) * 180 / Math.PI;
			TweenUtils.entityTo(getEntityById("gun"), Spatial, 2, {x:gunTarget.x, y:gunTarget.y, rotation:gunRotation, onComplete:idle});
		}
		
		private function idle():void
		{
			addSystem(new WaveMotionSystem());
			var gun:Entity = getEntityById("gun");
			gun.add(new WaveMotion()).add(new SpatialAddition());
			var wave:WaveMotion = gun.get(WaveMotion);
			wave.data.push(new WaveMotionData("y", 10,.05));
		}
		
		private function panic():void
		{
			Dialog(cj.get(Dialog)).sayById("run");
			CharUtils.setAnim(cj, Grief);
		}
		
		private function runForIt():void
		{
			player.remove(Threshold);
			SceneUtil.setCameraTarget(this, player);
			var cjsPath:Vector.<Point> = new Vector.<Point>();
			cjsPath.push(new Point(775,500),new Point(925,325),new Point(1475, 400));
			var playerTarget:Spatial = getEntityById("doorSilvaOfficeShrunk01").get(Spatial);
			CharUtils.followPath(cj,cjsPath, null,false);
			CharUtils.moveToTarget(player, playerTarget.x, playerTarget.y,false,beginBossFight);
		}
		
		private function beginBossFight(...args):void
		{
			shellApi.loadScene(SilvaOfficeShrunk01,3320,1290,"left");
		}
	}
}