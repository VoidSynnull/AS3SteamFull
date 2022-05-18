package game.scenes.reality2.shared
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Timer;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.DanceMoves01;
	import game.data.animation.entity.character.Proud;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.CoinEmitter;
	import game.scene.SceneSound;
	import game.scene.template.ActionsGroup;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionChain;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class RankingsPopup extends Popup
	{
		private var content:MovieClip;
		private var hud:MovieClip;
		private var charGroup:CharacterGroup;
		private var scene:Contest;
		private var contestants:XML;
		private var npcsToLoad:int = 0;
		private var actionsGroup:ActionsGroup;
		private var gameNumber:int;
		
		private const RESULTS_THEME:String		= "river_chase.mp3";
		
		//private const RANKINGS:String = "Rankings";

		public function RankingsPopup(container:DisplayObjectContainer=null, scene:Contest=null)
		{
			super(container);
			this.scene = scene;
			RealityScene.getNumGamesPlayed(scene.shellApi, numGamesDetermined);
		}
		
		private function numGamesDetermined(numGames:int):void
		{
			gameNumber = numGames;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/reality2/shared/";
			super.screenAsset = "rankings.swf";
			
			super.darkenBackground = true;
			super.darkenAlpha =1;
			super.autoOpen = false;
			super.init(container);
			//shellApi.loadFiles(shellApi.dataPrefix+RealityScene.CONTESTANTS_PATH, contestantDataLoaded);
			loadFiles(["contestants.xml","actions.xml","dialog.xml"],false,true,filesLoaded);
		}
		
		protected function filesLoaded():void
		{
			startMusic();
			contestants = getData("contestants.xml");
			var data:XML = getData("actions.xml", true);
			if(data)
			{
				actionsGroup = new ActionsGroup();
				actionsGroup.setupGroup(this, data);
			}
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content;
			content.x = shellApi.viewportWidth/2;
			content.y = shellApi.viewportHeight/2;
			
			setUpForeAndBackgrounds();
			setUpHud();
			setUpFire();
			setUpCoins();
			setUpDialog();
		}
		
		private function startMusic():void
		{
			AudioUtils.getAudio(parent, SceneSound.SCENE_SOUND).setVolume(0,SoundModifier.MUSIC);
			var audio:Audio = AudioUtils.getAudio(this);
			audio.play(SoundManager.MUSIC_PATH + RESULTS_THEME,true);
			audio.fade(SoundManager.MUSIC_PATH + RESULTS_THEME,shellApi.profileManager.active.musicVolume, NaN, 0, SoundModifier.MUSIC);
		}
		
		private function setUpForeAndBackgrounds():void
		{
			var clip:MovieClip = content["fg"];
			convertToBitmapSprite(clip);
			clip = content["bg"];
			convertToBitmapSprite(clip);
		}
		
		private function setUpDialog():void
		{
			var dialog:CharacterDialogGroup = new CharacterDialogGroup();
			dialog.setupGroup(this,getData("dialog.xml"),screen);
			var entity:Entity = getEntityById("probably");
			CharUtils.assignDialog(entity,this,"",false,0,1,false);
			entity = getEntityById("player");
			CharUtils.assignDialog(entity,this,"",false,0,1,false);
		}
		
		private function setUpCoins():void
		{
			var clip:MovieClip;
			var entity:Entity;
			
			for(var i:int = 1; i <= 3; i++)
			{
				clip = content["coin"+i];
				convertContainer(clip);
				DisplayUtils.moveToTop(clip);
				entity = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertAllClips(clip,null,this,true,32,entity);
				entity.add(new Id(clip.name));
				Sleep(entity.get(Sleep)).ignoreOffscreenSleep = true;
				EntityUtils.visible(entity, false);
			}
		}
		
		private function setUpFire():void
		{
			var clip:MovieClip = content["fire"];
			convertContainer(clip);
			TimelineUtils.convertAllClips(clip, null, this);
		}
		
		private function setUpHud():void
		{
			hud = content["hud"];
			hud.y = -shellApi.viewportHeight/2 + 15;
			charGroup = new CharacterGroup();
			charGroup.setupGroup(this);
			var participant:Contestant;
			var prefix:String;
			var look:LookData;
			var npc:XML;
			var child:XML;
			
			RealityScene.determineParticipantPlaces(scene.contestants);
			
			for(var i:int = 0; i < scene.participants.length; i++)
			{
				participant = scene.participants[i];
				if(participant.difficulty == Contestant.PLAYER)
				{
					prefix = "player";
					var playerLook:PlayerLook = shellApi.profileManager.active.look;
					look = new LookConverter().lookDataFromPlayerLook(playerLook);
				}
				else
				{
					prefix = "c"+i;
					npc = contestants.child("npc")[participant.index];
					child = npc.child("skin")[0];
					look = new LookData(child);
				}
				
				setUpUi(prefix, i, look, npcLoaded);
				charGroup.createDummy(prefix,look,"right","",content[prefix],this,npcLoaded,false);
			}
			
			npc = contestants.child("host")[0];
			child = npc.child("skin")[0];
			look = new LookData(child);
			prefix = "probably";
			charGroup.createDummy(prefix,look,"right","",content[prefix],this,npcLoaded,false);
		}
		
		private function npcLoaded(entity:Entity):void
		{
			npcsToLoad++;
			if(npcsToLoad >= scene.contestants.length * 2 + 1)//(* 2 is for ui and npcs)(+ 1 is for probably)
			{
				trace("all npcs ready");
				super.open();
				var suffix:String = gameNumber >1?""+gameNumber:"";
				var actionChain:ActionChain = actionsGroup.getActionChain("ceremony"+suffix);
				
				if(actionChain)
				{
					actionChain.execute();
				}
			}
		}
		
		protected function setUpUi(prefix:String, index:int, look:LookData, onComplete:Function = null):void
		{
			var clip:MovieClip =hud[prefix+"Ui"];
			
			var participant:Contestant = scene.participants[index];
			var contestant:Contestant = scene.getContestantFromParticipant(participant);
			
			clip.mouseChildren = clip.mouseEnabled = false;
			clip.x = 30 -clip.parent.width/2 + index/scene.contestants.length * clip.parent.width;
			
			TextUtils.refreshText(clip["score"],"CreativeBlock BB").text = "" + contestant.score;
			
			TextUtils.refreshText(clip["place"],"CreativeBlock BB").text = "" + contestant.place;
			
			var portrait:MovieClip = clip["portrait"];
			
			charGroup.createDummy(prefix+"Portrait",look,"right","head",portrait,this,onComplete,false,.25);
		}
		
		public function awardPlace(place:int):void
		{
			var contestant:Contestant;
			var entity:Entity;
			var coin:Entity;
			var id:String;
			for(var i:int = 0; i < scene.participants.length; i++)
			{
				contestant = scene.participants[i];
				if(contestant.place == place)
				{
					id = i > 0?"c"+i:"player";
					entity = getEntityById(id);
					break;
				}
			}
			if(place <= RealityScene.NUM_AIS)
			{
				coin = getEntityById("coin"+place);
				var npcPosition:MovieClip = content[id];
				var coinSpatial:Spatial = coin.get(Spatial);
				coinSpatial.x = 0;
				coinSpatial.y = -shellApi.viewportHeight/2 + 100;
				EntityUtils.visible(coin, true, true);
				
				var final:Function = Command.create(TweenUtils.entityTo,coin, Spatial, 1, {y:npcPosition.y - 150, ease:Quad.easeInOut, onComplete:Command.create(celebrate,entity,place,contestant)});
				var prepare:Function = Command.create(TweenUtils.entityTo,coin, Spatial, 1, {y:-shellApi.viewportHeight, x:npcPosition.x, ease:Quad.easeInOut, onComplete:final});
				var pass:Function = Command.create(TweenUtils.entityTo,coin, Spatial, 1, {x:-shellApi.viewportWidth/2, ease:Quad.easeInOut, onComplete:prepare});
				TweenUtils.entityTo(coin, Spatial, 1, {x:shellApi.viewportWidth/2, ease:Quad.easeInOut, onComplete:pass});
			}
			else
			{
				celebrate(entity, place, contestant);
			}
			
			trace(place + ": " + contestant.id + ": " + contestant.score);
		}
		
		private function celebrate(entity:Entity, place:int, participant:Contestant):void
		{
			var celebration:Class;
			switch(place)
			{
				case 1:
				{
					celebration = Celebrate;
					break;
				}
				case 2:
				{
					celebration = DanceMoves01;
					break;
				}
				case 3:
				{
					celebration = Proud;
					break;
				}
				default:
				{
					celebration = Cry;
					break;
				}
			}
			
			CharUtils.setAnim(entity, celebration);
			
			points = RealityScene.getScoreFromPlace(place);
			var id:String = entity.get(Id).id;
			var clip:MovieClip = hud[id+"Ui"];
			var tf:TextField = clip["score"];
			var contestant:Contestant = scene.getContestantFromParticipant(participant);
			
			var timer:Timer = SceneUtil.getTimer( this );
			var timedEvent:TimedEvent = new TimedEvent( .1, points, Command.create(updateScore, tf, contestant) );
			timer.addTimedEvent( timedEvent );
			
			var destination:Point = new Point(hud.x + clip.x +clip.width/2, hud.y + clip.y + clip.height /2);
			
			var origin:DisplayObjectContainer = EntityUtils.getDisplay(entity).container;
			
			var emitter:CoinEmitter = new CoinEmitter(points, destination, new Point(origin.x, origin.y));
			EmitterCreator.create(this, content, emitter);
		}
		
		private var points:int;
		
		private function updateScore(tf:TextField, contestant:Contestant):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"coin_toss_0"+Math.ceil(Math.random() * 4)+".mp3");
			contestant.score++;
			tf.text = ""+ contestant.score;
			points--;
			if(points > 0)
				return;
			
			RealityScene.determineParticipantPlaces(scene.contestants);
			var clip:MovieClip;
			for(var i:int = 0; i < scene.contestants.length; i++)
			{
				contestant = scene.contestants[i];
				if(contestant.difficulty == Contestant.PLAYER)
				{
					clip = hud["playerUi"];
				}
				else
				{
					clip = hud["c"+(i+1)+"Ui"];
				}
				tf = clip["place"];
				tf.text = ""+contestant.place;
			}
		}
	}
}