package game.scenes.hub.shared.managers
{
	import flash.display.DisplayObjectContainer;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.scene.SceneItemCreator;
	import game.data.profile.ProfileData;
	import game.proxy.DataStoreRequest;
	import game.scene.template.GameScene;
	import game.scenes.tutorial.TutorialEvents;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;

	public class ShardManager
	{
		public function ShardManager(scene:Scene, winFunction:Function, timeline:Timeline)
		{
			_scene = scene;
			_winFunction = winFunction;
			_timeline = timeline;
		}
		
		/**
		 * Add shards to scene 
		 * @param container
		 * 
		 */
		public function addShards(container:DisplayObjectContainer):void
		{
			// get user field with server fallback
			var fromServer:Boolean = !_scene.shellApi.profileManager.active.isGuest;
			_scene.shellApi.getUserField(SHARDS_FIELD, _scene.shellApi.island, Command.create(setupShards, container), fromServer);
		}
		
		public function setupShards(shards:Array, container:DisplayObjectContainer):void
		{
			trace("current shards: " + shards);
			_shards = shards;
			
			if(!_shards)
			{
				_shards = [];
				_scene.shellApi.setUserField(SHARDS_FIELD, _shards, _scene.shellApi.island, true);
			}
			
			_timeline.gotoAndStop(_shards.length);
			
			var sceneCreator:SceneItemCreator = new SceneItemCreator();
			
			for (var n:Number = container.numChildren - 1; n >= 0; n--)
			{
				var clip:DisplayObjectContainer = container.getChildAt(n) as DisplayObjectContainer;
				
				if (clip != null)
				{
					if(clip.name.indexOf(SHARD_ID) > -1)
					{
						if(_shards)
						{
							if(_shards.indexOf(clip.name) > -1)
							{
								container.removeChild(clip);
								continue;
							}
						}
						var shard:Entity = new Entity();
						shard.add(new Spatial());
						shard.add(new Sleep());
						var display:Display = new Display(clip);
						display.isStatic = true;
						shard.add(display);
						shard.add(new Id(clip.name));
						clip.mouseEnabled = false;
						clip.mouseChildren = false;
						_scene.addEntity(shard);
						sceneCreator.make(shard, new Point(25, 100), false);
					}
				}
			}
			
			// add kistener to ItemHitSystem
			var itemHitSystem:ItemHitSystem = _scene.getSystem(ItemHitSystem) as ItemHitSystem;
			if( itemHitSystem == null )
			{
				itemHitSystem = new ItemHitSystem();
				_scene.addSystem(itemHitSystem, SystemPriorities.resolveCollisions);
			}
			itemHitSystem.gotItem.add(handleGotItem);
		}
		
		public function handleGotItem(item:Entity):void
		{
			var dialog:Dialog = _scene.shellApi.player.get(Dialog);
			var active:ProfileData = _scene.shellApi.profileManager.active;
			var itemID:String = item.get(Id).id;
			
			//make sure item is a shard
			if( itemID.indexOf(SHARD_ID) != -1 )
			{				
				_shards.push(itemID);
				// save to database
				_scene.shellApi.siteProxy.store(DataStoreRequest.itemGainedStorageRequest(itemID, "tutorial"));
				// update coin hud
				_timeline.gotoAndStop(_timeline.currentIndex + 1);
				
				_scene.shellApi.setUserField(SHARDS_FIELD, _shards, _scene.shellApi.island, true);
				
				var shardsRemaining:Number = TOTAL_SHARDS - _shards.length;
				
				var shardSound:String = "effects/points_ping_0";
				var pingNumber:uint = 2;//1,2,3,4 for the differnt pings
				var pingynessArray:Array = ["d.mp3","c.mp3","b.mp3","a.mp3","e.mp3"];
				
				var pingyness:int = shardsRemaining / 2;
				if(shardsRemaining == 0 && pingNumber == 4)
					pingyness = 4;
				if(pingNumber < 4 && shardsRemaining > 0 && pingyness < 3)
					++pingyness
				
				var soundToPlay:String = shardSound + pingNumber + pingynessArray[pingyness];
				
				AudioUtils.play(_scene,soundToPlay);
				
				_scene.shellApi.track("CoinFound", _shards.length);
				
				_lastShardID = int(itemID.substr(5));
				if(_shards.length < TOTAL_SHARDS)
				{
					var shardText:String = "coins";
					
					if(_shards.length == TOTAL_SHARDS - 1)
					{
						shardText = "coin";
					}
					
					dialog.say(shardsRemaining + " more " + shardText + " to find!");
					
					// set number of coins
					var coins:int = 5;
					
					// testing function
					//SceneUtil.delay(_scene, 2, testAnim);
				}
				// if get all coins
				else
				{
					_scene.shellApi.track("IslandCompleted");
					_scene.shellApi.track("FoundAllCoins");
					_scene.shellApi.triggerEvent(TutorialEvents.FOUND_ALL_COINS, true);
					// set number of coins
					coins = 15;
					// lock for sequence
					SceneUtil.lockInput(_scene);
					// delay for card (allow coin animation first)
					SceneUtil.delay(_scene, 2, showCard);
				}
				var credits:int = coins * 5;
				_scene.shellApi.profileManager.active.credits += credits;
				_scene.shellApi.profileManager.save();
				// show coins
				SceneUtil.getCoins(GameScene(_scene), Math.round(coins));
				// send to page
				if (ExternalInterface.available)
				{
					var transactionID:String = _scene.shellApi.profileManager.active.login;
					if ((transactionID == null) || (transactionID == ""))
						transactionID = _scene.shellApi.profileManager.active.avatarName;
					ExternalInterface.call("tutorialCompleted", transactionID);
				}
			}
		}
		
		private function testAnim():void
		{
			_winFunction(_lastShardID, true);
		}
		
		private function showCard():void
		{
			// get card
			_scene.shellApi.getItem("all_coins", null, true, doneCard);
		}
		
		private function doneCard():void
		{
			// hover Amelia to player location and play dialog
			if (_winFunction != null)
			{
				_winFunction(_lastShardID);
			}
		}
	
		public function getShardCount():int
		{
			return _shards.length;
		}
		
		private const SHARDS_FIELD:String = "shards_found";
		private const SHARD_ID:String = "shard";
		
		private var _shardsFound:Number = 8;
		private const TOTAL_SHARDS:int = 8;
		private var _scene:Scene;
		private var _shards:Array;
		private var _winFunction:Function;
		private var _lastShardID:int;
		private var _timeline:Timeline;
	}
}