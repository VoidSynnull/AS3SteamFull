package game.scenes.start.login.groups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.scenes.start.login.components.BackgroundAnimation;
	import game.scenes.start.login.data.BackgroundAnimationData;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class BackgroundAnimationsGroup extends DisplayGroup
	{
		private var themePath:String;
		private var animations:Dictionary;
		private var last:Dictionary;
		public var animsLoaded:Signal;
		
		private const PADDING:Number = 50;
		
		private const PADDING_BOT:Number = 100;
		
		private const TYPE:String	= "type";
		
		private var animationTypes:Array = [BackgroundAnimationData.BOTTOM,BackgroundAnimationData.TOP,BackgroundAnimationData.LEFT, BackgroundAnimationData.RIGHT];
		
		public function BackgroundAnimationsGroup(container:DisplayObjectContainer=null)
		{
			last = new Dictionary();
			last[TYPE] = "none";
			animsLoaded = new Signal();
			super(container);
		}
		
		public function config(themePath:String):void
		{
			this.themePath;
			loadFile(themePath, onThemeLoaded);
		}
		
		private function onThemeLoaded(xml:XML):void
		{
			if(xml == null)
			{
				trace(" background data: " + themePath + " could not be found.");
				return;
			}
			animations = new Dictionary();
			var assets:Array = [];
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				var group:XML = xml.children()[i];
				var prefix:String = "";
				var type:String = "";
				if(group.hasOwnProperty("@prefix"))
				{
					prefix = DataUtils.getString(group.attribute("prefix")[0]);
				}
				if(group.hasOwnProperty("@type"))
				{
					type = DataUtils.getString(group.attribute("type")[0]);
				}
				
				for(var a:int = 0; a < group.children().length(); a++)
				{
					var anim:XML = group.children()[a];
					var animData:BackgroundAnimationData = new BackgroundAnimationData(anim, prefix, type);
					//get the list of animations by type or create if it does not exist
					var animList:Vector.<BackgroundAnimationData>;
					if(animations.hasOwnProperty(animData.type))
					{
						animList = animations[animData.type];
					}
					else
					{
						animList = new Vector.<BackgroundAnimationData>();
						animations[animData.type] = animList;
					}
					animList.push(animData);
					if(assets.indexOf(animData.Url) == -1)
					{
						assets.push(animData.Url);
					}
				}
			}
			loadFiles(assets,true,true,onAssetsLoaded);
		}
		
		private function onAssetsLoaded():void
		{
			for (var type:String in animations)
			{
				var animList:Vector.<BackgroundAnimationData> = animations[type];
				for(var i:int = 0; i < animList.length; i++)
				{
					var bgAnimData:BackgroundAnimationData = animList[i];
					bgAnimData.asset = getAsset(bgAnimData.Url, true, true, true);
				}
			}
			animsLoaded.dispatch();
		}
		
		public function createBackgroundAnim(type:String):Entity
		{
			var entity:Entity = null;
			if(animations.hasOwnProperty(type) && last[this.TYPE] != type)
			{
				var animList:Vector.<BackgroundAnimationData> = animations[type];
				var index:int = int(Math.random() * animList.length);
				var anim:BackgroundAnimationData = animList[index];
				if(anim.asset is Entity)
				{
					entity = anim.asset;
					if(entity.get(Tween) || last.hasOwnProperty(type) && last[type] == entity)
						entity = null;
					else
						last[type] = entity;
				}
				if(anim.asset is DisplayObject)
				{
					entity = EntityUtils.createSpatialEntity(parent, anim.asset, container);
					if(anim.asset is MovieClip)
					{
						TimelineUtils.convertAllClips(anim.asset, null,parent, true,32,entity);
					}
					entity.add(new BackgroundAnimation(anim));
					anim.asset = entity;
					last[type] = entity;
				}
			}
			if(entity != null)
			{
				last[this.TYPE] = type;
			}
			return entity;
		}
		
		public function tweenAnimation(entity:Entity, onComplete:Function = null):void
		{
			if(entity == null)
			{
				if(onComplete != null)
				{
					onComplete();
				}
				return;
			}
			
			var anim:BackgroundAnimation = entity.get(BackgroundAnimation);
			
			var spatial:Spatial = entity.get(Spatial);
			var x:Number;
			var y:Number;
			var duration:Number = anim.data.time;
			var ease:Function = anim.data.ease;
			var easeComplete:Function= Command.create(tweenComplete, entity, onComplete);
			switch(anim.data.type)
			{
				case BackgroundAnimationData.BOTTOM:
				{
					spatial.y = shellApi.viewportHeight * 1.5;
					spatial.x = PADDING + (shellApi.viewportWidth - PADDING * 2) * Math.random();
					x = spatial.x;
					y = -shellApi.viewportHeight / 2;
					break;
				}
				case BackgroundAnimationData.TOP:
				{
					spatial.y = -shellApi.viewportHeight / 2;
					spatial.x = PADDING + (shellApi.viewportWidth - PADDING * 2) * Math.random();
					x = spatial.x;
					y = shellApi.viewportHeight * 1.5;
					break;
				}
				case BackgroundAnimationData.LEFT:
				{
					spatial.y = PADDING + (shellApi.viewportHeight - PADDING_BOT * 2) * Math.random();
					spatial.x = -shellApi.viewportWidth / 2;
					x = shellApi.viewportWidth * 1.5;
					y = spatial.y;
					break;
				}
				case BackgroundAnimationData.RIGHT:
				{
					spatial.y = PADDING + (shellApi.viewportHeight - PADDING_BOT * 2) * Math.random();
					spatial.x = shellApi.viewportWidth * 1.5;
					x = -shellApi.viewportWidth /2;
					y = spatial.y;
					break;
				}
			}
			
			TweenUtils.entityTo(entity, Spatial, duration,{x:x, y:y, ease:ease, onComplete:easeComplete});
		}
		
		private function tweenComplete(entity:Entity, onComplete:Function = null):void
		{
			entity.remove(Tween);
			if(onComplete != null)
			{
				onComplete();
			}
		}
		
		public function createRandomAnimation(onComplete:Function = null):void
		{
			var index:int = int(animationTypes.length * Math.random());
			tweenAnimation(createBackgroundAnim(animationTypes[index]), onComplete);
		}
	}
}