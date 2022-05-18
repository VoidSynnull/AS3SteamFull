package game.scenes.deepDive1.shared.creators
{
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.DisplayGroup;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.scenes.deepDive1.shared.components.Geyser;
	import game.util.DisplayUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;


	public class GeyserCreator
	{		
		public static function create(geyserBody:Entity, geyserClip:MovieClip, bubbleBitmapData:BitmapData, group:DisplayGroup, interactiveJet:Boolean, autoPlay:Boolean = false):Entity
		{
			if(!autoPlay){
				geyserBody = TimelineUtils.convertClip(geyserClip.parent as MovieClip,group,geyserBody,null,false);
				geyserBody.get(Timeline).stop();
			} else {
				geyserBody = TimelineUtils.convertClip(geyserClip.parent as MovieClip,group,geyserBody);
			}
			/*
			var bubbleAsset:MovieClip = bubbleclip;
			// we get its bitmapData using DisplayUtils 
			var bitmapData:BitmapData = DisplayUtils.returnBitmapData(bubbleAsset);
			*/
			
			// create the on emitter
			var geyserOn:Entity = EmitterCreator.create( group, geyserClip, GeyserCreator.makeGeyserOn(bubbleBitmapData), 0, 0, geyserBody );
			geyserOn.add(new Id("jetOn"));
			// create the off emitter
			var geyserOff:Entity = EmitterCreator.create( group, geyserClip, GeyserCreator.makeGeyserOff(bubbleBitmapData), 0, 0, geyserBody );
			geyserOff.add(new Id("jetOff"));
			
			var geyser:Geyser;
			if(interactiveJet){
				geyser = new Geyser(true, geyserOn.get(Emitter),geyserOff.get(Emitter));
				geyserBody.add(geyser);
				geyser.turnOn();
			}else{
				geyser = new Geyser(false, geyserOn.get(Emitter),geyserOff.get(Emitter));
				geyserBody.add(geyser);
				geyser.turnOff();
			}
			
			geyserBody.add(new Sleep());
			
			return geyserBody;
		}
		
		private static function makeGeyserOn(bitmapData:BitmapData):Emitter2D
		{
			var bitmapEmitter:Emitter2D = new Emitter2D();
			bitmapEmitter.counter = new Steady( BUBBLE_NUM_ON );
			
			bitmapEmitter.addInitializer( new BitmapImage(bitmapData) );
			bitmapEmitter.addInitializer( new Lifetime( 0.5, 1 ) );
			bitmapEmitter.addInitializer( new Position( new LineZone(new Point(9,2),new Point(-12,-2)) ) );
			bitmapEmitter.addInitializer( new Velocity( new LineZone(new Point(30,-300),new Point(-30,-200)) ) );
			bitmapEmitter.addInitializer( new ScaleImageInit( 0.8, 1.0) );
			
			bitmapEmitter.addAction( new Age() );
			bitmapEmitter.addAction( new Move() );
			bitmapEmitter.addAction( new Accelerate(0,-40) );
			bitmapEmitter.addAction( new Fade(1,0.15) );
			return bitmapEmitter;
		}	
		
		private static function makeGeyserOff(bitmapData:BitmapData):Emitter2D
		{
			var bitmapEmitter:Emitter2D = new Emitter2D();
			bitmapEmitter.counter = new Steady( BUBBLE_NUM_OFF );
			
			bitmapEmitter.addInitializer( new BitmapImage(bitmapData) );
			bitmapEmitter.addInitializer( new Lifetime( 0.2, 0.3) );
			bitmapEmitter.addInitializer( new Position( new LineZone(new Point(10,2),new Point(-12,-2)) ) );
			bitmapEmitter.addInitializer( new Velocity( new LineZone(new Point(60,-250),new Point(-60,-200)) ) );
			bitmapEmitter.addInitializer( new ScaleImageInit( 0.8, 1.0) );
			
			bitmapEmitter.addAction( new Age() );
			bitmapEmitter.addAction( new Move() );
			bitmapEmitter.addAction( new Fade(1,0.10) );
			return bitmapEmitter;
		}
		
		public static const BUBBLE_NUM_ON:uint = 15;
		public static const BUBBLE_NUM_OFF:uint = 5;
	}
}