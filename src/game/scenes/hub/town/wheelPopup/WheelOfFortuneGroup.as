package game.scenes.hub.town.wheelPopup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.motion.MotionThreshold;
	import game.components.motion.Threshold;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.proxy.PopDataStoreRequest;
	import game.scene.template.ui.CardGroup;
	import game.systems.SystemPriorities;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	public class WheelOfFortuneGroup extends Group
	{
		//convenience so i dont have to get them over and over
		private var wheelEntity:Entity;
		private var wheel:PrizeWheel;
		private var degreesPerWedge:Number;
		//crucial for the wheel functionality
		private var prize:PrizeData;
		private var prizeIndex:int;
		private var isMember:String = "";
		private var testing:Boolean;
		public function WheelOfFortuneGroup(testing:Boolean = false)
		{
			this.testing = testing;
			super();
		}
		
		public function createWheelOfFortune(data:*, container:DisplayObjectContainer = null, wheelComplete:Function = null):void
		{
			if(data is String)
				shellApi.loadFile(data, Command.create(parseData, container, wheelComplete));
			else if(data is PrizeWheelData)
				createPrize(data, container, wheelComplete);
			else if(data == null)
				parseData(null, container, wheelComplete);
			else
				trace("could not create wheel from data given");
		}
		
		private function parseData(xml:XML, container:DisplayObjectContainer, wheelComplete:Function):void
		{
			var data:PrizeWheelData = new PrizeWheelData(xml);
			createPrize(data, container, wheelComplete);
		}
		
		private function createPrize(data:PrizeWheelData, container:DisplayObjectContainer, wheelComplete:Function):void
		{
			var asset:DisplayObjectContainer;
			
			if(DataUtils.validString(data.asset))
			{
				if(data.asset.indexOf(".swf") > 0)// load swf
				{
					shellApi.loadFile(data.asset, Command.create(assetLoaded, data, container, wheelComplete));
				}
				else//find a clip in the container
				{
					var assetName:String = data.asset;
					var start:int = 0;
					var index:int = assetName.indexOf(".");
					if(index > 0)//it is a child layered multiple levels with in the container
					{
						asset = container;
						while(index>0 && asset)
						{
							container = asset;
							asset = container[assetName.substr(start, index)];
							assetName = assetName.substr(index);
							start = index;
							index = assetName.indexOf(".");
						}
					}
					else
						asset = container[assetName];
					
					assetLoaded(asset, data, container, wheelComplete);
				}
			}
			else//it's not an asset to be loaded nor a clip inside the container
			{
				// the given container is the asset
				asset = container;
				container = null;
				assetLoaded(asset, data, container, wheelComplete);
			}
		}
		
		private function assetLoaded(asset:DisplayObjectContainer, data:PrizeWheelData, container:DisplayObjectContainer, wheelComplete:Function):void
		{
			if(asset == null)
			{
				trace("asset could not be found.");
				wheelComplete(null);
				return;
			}
			if(asset.hasOwnProperty("content"))//if loaded in make sure its asset is not the swf
			{
				asset = asset["content"];
			}
			
			var clip:MovieClip = asset["wheel"];
			
			adjustWeighting(data);
			
			wheelEntity = EntityUtils.createMovingEntity(this, clip);
			wheel = new PrizeWheel(data);
			degreesPerWedge = 360 / data.prizes.length;
			addSystem(new MotionThresholdSystem(), SystemPriorities.checkCollisions);
			addSystem(new ThresholdSystem(), SystemPriorities.moveComplete);
			
			wheelEntity.add(new Id("wheel")).add(new MotionThreshold("rotationVelocity", "<"))
				.add(new Threshold("rotation", ">")).add(new Id(WHEEL_OF_FORTUNE)).add(wheel);
			
			determinePrizesToDisplay(wheelComplete);
		}
		
		// if weights are not specified, divy up the rest evenly
		private function adjustWeighting(data:PrizeWheelData):void
		{
			var prizeData:PrizeData;
			var weightGiven:Number = 0;
			var remainingWeights:int = data.prizes.length;
			for(var i:int = 0; i < data.prizes.length; i++)
			{
				prizeData = data.prizes[i];
				if(!isNaN(prizeData.weight))
				{
					remainingWeights--;
					weightGiven += prizeData.weight;
				}
			}
			var weightDistribution:Number = (100 - weightGiven) /remainingWeights;
			for(i = 0; i < data.prizes.length; i++)
			{
				prizeData = data.prizes[i];
				if(isNaN(prizeData.weight))
				{
					prizeData.weight = weightDistribution;
				}
			}
		}
		
		private function determinePrizesToDisplay(wheelComplete:Function):void
		{
			var inventory:PrizeInventoryData;
			var prizeData:PrizeData;
			var prizes:Array = [];
			var profile:ProfileData = shellApi.profileManager.active;
			
			trace("is member: " + profile.isMember + ", is test: " + wheel.data.test + ", age: " + profile.age);
			
			if(profile.isMember && wheel.data.test && profile.age == 0|| profile.isMember && !wheel.data.test)//if designated a test only work if profile is age 0
				isMember = "Member";
			
			for(var i:int = 0; i < wheel.data.prizes.length; i++)
			{
				var prizeType:PrizeData = wheel.data.prizes[i];
				
				if(prizeType.type == AGAIN)// spin again
				{
					prizes.push(AGAIN);
					continue;
				}
				
				inventory = wheel.data.inventory[prizeType.id];
				prizeData = wheel.data.getRandomPrizeFromInventory(prizeType.id+isMember);
				
				if(prizeData == null)// if you are all out of items to try from
				{
					prizes.push(null);
					trace("could not find a unique prize for: " + prizeType.id+isMember);
					continue;
				}
				
				if(prizeData.unique)// if it is an item any player should only get once
				{
					var index:int;
					// gotta handle how to deal with player already having every thing there was to offer
					while(shellApi.checkItemEvent(prizeData.prize,false, CardGroup.STORE) || prizeData.gender != null && prizeData.gender != shellApi.profileManager.active.gender)//if you have the item already
					{
						index = inventory.prizes.indexOf(prize);
						inventory.prizes.splice(index, 1);// take it out of the mix
						prizeData = wheel.data.getRandomPrizeFromInventory(prizeType.id+isMember);//get a new random prize
						if(prizeData == null)// if you are all out of items to try from
						{
							prizes.push(null);
							trace("could not find a unique prize for: " + prizeType.id+isMember);
							continue;
						}
					}
					
					prizeType.gender = prizeData.gender;
				}
				prizeType.type = prizeData.type;
				prizeType.unique = prizeData.unique;
				prizeType.prize = prizeData.prize;
				prizes.push(prizeType.type+": "+prizeType.prize);
			}
			
			shellApi.track("todays_prizes", JSON.stringify(prizes));
			determinedPrizes(wheelComplete);
		}
		
		private function determinedPrizes(wheelComplete:Function):void
		{
			var clip:MovieClip = EntityUtils.getDisplayObject(wheelEntity) as MovieClip;
			var tf:TextField;
			var tfContainer:MovieClip;
			var prizeData:PrizeData;
			var filters:Array;
			
			for(var i:int = 0; i < wheel.data.prizes.length; i++)
			{
				prizeData = wheel.data.prizes[i];
				if(prizeData.id == "again" || prizeData.id=="grandPrize" || prizeData.id=="grandPrizeMember")
					continue;
				
				tfContainer = clip[prizeData.id];
				filters = tfContainer.filters;
				tfContainer.filters = [];
				
				tf = tfContainer["tf"];
				tf = TextUtils.refreshText(tf, "PoplarStd");
				tf.text = prizeData.prize;
				tf.filters = filters;
			}
			if(wheelComplete)
				wheelComplete(wheelEntity);
		}
		
		public function spinWheel(stoppedOnPrize:Function = null):void
		{
			getPrizeData(stoppedOnPrize);
		}
		
		private function getPrizeData(stoppedOnPrize:Function = null):void
		{
			shellApi.track("spin_wheel");
			if(testing)// mobile is trying to resemble web as much as possible
			{
				prizeIndex = wheel.randomPrizeNumber;
				
				prize = wheel.data.prizes[prizeIndex];
				
				if(prize.type == AGAIN)// spin again
				{
					trace("You will get to Spin Again!");
					startWheel(stoppedOnPrize);
				}
				else 
				{
					if(prize.type == CREDITS)
					{
						trace("you will get " + prize.prize + " " + CREDITS);
					}
					else
					{
						trace("you will get store item # " + prize.prize);
					}
					startWheel(stoppedOnPrize);
				}
			}
			else
			{
				var prizes:Array = formatPrizes();
				shellApi.siteProxy.retrieve(PopDataStoreRequest.getRandomWinner(prizes),Command.create(returnedRequestFromServer, stoppedOnPrize));
				trace("request info from server");
			}
		}
		
		private function formatPrizes():Array
		{
			var prizes:Array = [];
			var obj:Object;
			var prizeData:PrizeData;
			for(var i:int = 0; i < wheel.data.prizes.length; i++)
			{
				prizeData = wheel.data.prizes[i];
				obj = new Object();
				obj.type = prizeData.type;
				obj.id = prizeData.id+isMember;
				obj.prize = prizeData.prize;
				prizes.push(obj);
			}
			return prizes;
		}
		
		private function returnedRequestFromServer(requestData:PopResponse, stoppedOnPrize:Function = null):void
		{
			if(requestData.succeeded)
			{
				prizeIndex = DataUtils.getNumber(requestData.data.index);
				prize = wheel.data.prizes[prizeIndex];
				// have to do these things so game is updated in real time 
				// not having to make player log out and back in again to update
				if(prize.type== CREDITS)
					shellApi.profileManager.updateCredits();
				else if(prize.type != AGAIN)
					shellApi.getItem(prize.prize, CardGroup.STORE);
				// now that all the back end stuff is sorted out
				// now its time for all the visuals
				startWheel(stoppedOnPrize);
			}
			else
			{
				trace("was unable to get a proper response from the server");
				stoppedOnPrize(null);
			}
		}
		
		private function startWheel(stoppedOnPrize:Function = null):void
		{
			var motion:Motion = wheelEntity.get(Motion);
			motion.rotationFriction = 0;
			motion.rotationAcceleration = 720;
			var threshold:MotionThreshold = wheelEntity.get(MotionThreshold);
			threshold.threshold = 360;
			threshold.operator = ">";
			threshold.entered.addOnce(Command.create(upToSpeed, stoppedOnPrize));
		}
		
		private function upToSpeed(stoppedOnPrize:Function):void
		{
			Motion(wheelEntity.get(Motion)).rotationAcceleration = 0;
			trace("reached max speed");
			// make sure that the wheels rotation isn't a bajillion degrees
			var spatial:Spatial = wheelEntity.get(Spatial);
			spatial.rotation = spatial.rotation%360 - 360;
			
			var threshold:Threshold = wheelEntity.get(Threshold);
			threshold.isInside = false;
			threshold.threshold = degreesPerWedge * prizeIndex - degreesPerWedge / 2;
			threshold.operator=">";
			threshold.entered.addOnce(Command.create(decaySpeed,stoppedOnPrize));
		}
		
		private function decaySpeed(stoppedOnPrize:Function):void
		{
			var motion:Motion = wheelEntity.get(Motion);
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = 360;
			motion.rotationFriction = degreesPerWedge * 2;
			var threshold:MotionThreshold = wheelEntity.get(MotionThreshold);
			threshold.threshold = degreesPerWedge * 2;
			threshold.operator = "<";
			threshold.entered.addOnce(Command.create(slowToStop, stoppedOnPrize));
		}
		
		private function slowToStop(stoppedOnPrize:Function):void
		{
			// at this point we do not want to allow for performance variation to alter where the wheel will stop
			// take it out of motions hands and just tween to where we want it to go.
			var spatial:Spatial = wheelEntity.get(Spatial);
			
			var rotation:Number = spatial.rotation%360;
			var targetRotation:Number = degreesPerWedge * prizeIndex;
			var dif:Number = rotation - targetRotation;
			if(dif > 180)
				dif -= 360;
			else if(dif < -180)
				dif += 360;
			
			var variation:Number = Math.random() * degreesPerWedge / 2 - degreesPerWedge / 4;// allow for some variation so it does not seem so rigid
			
			dif += variation;
			
			var motion:Motion = wheelEntity.get(Motion);
			motion.rotationVelocity = 0;
			motion.rotationFriction = 0;
			
			var time:Number = Math.abs(dif) / degreesPerWedge;
			
			// change duration to account for potential variation of target rotation
			
			TweenUtils.entityTo(wheelEntity, Spatial, time, {rotation:spatial.rotation - dif, onComplete:Command.create(wheelStopped, stoppedOnPrize)});
		}
		
		private function wheelStopped(stoppedOnPrize:Function):void
		{
			shellApi.track("wheel_stopped", prize.id, prize.prize);
			if(stoppedOnPrize)// you were able to deliver a prize
				stoppedOnPrize(prize);
		}
		
		private static const CREDITS:String = "credits";
		private static const AGAIN:String = "again";
		
		public static const WHEEL_OF_FORTUNE:String = "wheelOfFortune";
	}
}