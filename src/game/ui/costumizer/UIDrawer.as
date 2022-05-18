package game.ui.costumizer {

import com.greensock.easing.Sine;

import flash.display.DisplayObjectContainer;

import ash.core.Entity;

import engine.components.Display;
import engine.components.Id;
import engine.components.Spatial;
import engine.components.Tween;
import engine.group.Group;

import game.ui.elements.UIElement;
import game.util.TweenUtils;
import game.util.Utils;

/**
 * UIDrawer is an interface element which sits just outside the Stage
 * until summoned.
 *
 * @author Rich Martin 
 */
public class UIDrawer extends UIElement 
{
	public static const VERTICAL_TRAVEL:uint	= 1;
	public static const HORIZONTAL_TRAVEL:uint	= 2;

	public static const DEFAULT_DURATION:Number	= 0.5;
	public static const DEFAULT_LERP:Function	= Sine.easeInOut;

	public static const OFFSCREEN_TOP:uint		= 1;
	public static const OFFSCREEN_RIGHT:uint	= 2;
	public static const OFFSCREEN_BOTTOM:uint	= 3;
	public static const OFFSCREEN_LEFT:uint		= 4;

	public static const HIDDEN_STATE:uint		= 0;
	public static const ARRIVING_STATE:uint		= 1;
	public static const SHOWING_STATE:uint		= 2;
	public static const DEPARTING_STATE:uint	= 3;

	public static function instanceFromInitializer(group:Group, view:DisplayObjectContainer, spec:Object):UIDrawer 
	{
		var drawerID:String = '';
		if (spec.hasOwnProperty('id')) {
			drawerID = spec.id;
		}
		return Utils.overlayObjectProperties(spec, new UIDrawer(group, view, drawerID)) as UIDrawer;
	}

	public var offscreenEdge:uint = 0;
	public var offscreenX:Number;
	public var offscreenY:Number;
	public var onscreenX:Number;
	public var onscreenY:Number;
	public var entranceDuration:Number;
	public var exitDuration:Number;
	public var entranceLerp:Function;
	public var exitLerp:Function;
	public var entranceCallback:Function;
	public var exitCallback:Function;
	public var drawerView:DisplayObjectContainer;

	private var drawerState:uint = HIDDEN_STATE;
	private var drawerEntity:Entity;

	public function UIDrawer(group:Group, view:DisplayObjectContainer, open:Boolean = false, id:String=null) 
	{
		drawerView = view;
		drawerEntity = new Entity()
			.add(new Display(drawerView))
			.add(new Spatial())
			.add(new Tween());
		if (id) {
			drawerEntity.add(new Id(id));
			drawerEntity.name = id;
		}
		group.addEntity(drawerEntity);
		
		this.drawerState = open ? SHOWING_STATE : HIDDEN_STATE;
	}
	
	override public function destroy():void
	{
		super.destroy();
		
		entranceLerp 		= null;
		exitLerp 			= null;
		
		entranceCallback 	= null;
		exitCallback		= null;
		
		drawerView 			= null;
		drawerEntity 		= null;
	}

	public function set visible(flag:Boolean):void 
	{
		var display:Display = drawerEntity.get(Display)
		display.visible = display.displayObject.visible = flag;
	}
	
	public function get visible():Boolean {
		return (drawerEntity.get(Display) as Display).visible;
	}

	public function get state():uint {
		return drawerState;
	}

	private function get isOperational():Boolean 
	{
		// is value valid?
		if ((0 < offscreenEdge) && (5 > offscreenEdge))
		{	
			if ((OFFSCREEN_TOP == offscreenEdge) || (OFFSCREEN_BOTTOM == offscreenEdge))
			{
				return !(isNaN(offscreenY) || isNaN(onscreenY));
			}
			else
			{ // must be OFFSCREEN_LEFT or OFFSCREEN_RIGHT
				return !(isNaN(offscreenX) || isNaN(onscreenX));
			}
		}
		return false;
	}

	private function get directionOfTravel():uint 
	{
		if (!isOperational) {
			throw new Error("Can't determine direction of uninitialized drawer");
		}
		if ((OFFSCREEN_TOP == offscreenEdge) || (OFFSCREEN_BOTTOM == offscreenEdge)) {
			return VERTICAL_TRAVEL;
		} else {
			return HORIZONTAL_TRAVEL;
		}
	}

	public function toggle():void 
	{
		if ((SHOWING_STATE == state) || (HIDDEN_STATE == state)) 
		{
			var tween:Tween = drawerEntity.get(Tween) as Tween;
			tween.to(drawerEntity.get(Spatial), transitionDuration(HIDDEN_STATE == state), tweenVars( this.directionOfTravel, HIDDEN_STATE == state));
			drawerState = (SHOWING_STATE == state) ? DEPARTING_STATE : ARRIVING_STATE;
		}
	}
	
	public function show( showDrawer:Boolean = true ):void 
	{
		if( showDrawer )
		{
			if ( HIDDEN_STATE == state ) 
			{
				TweenUtils.entityTo( drawerEntity, Spatial, transitionDuration(true), tweenVars(this.directionOfTravel, true));
				drawerState = ARRIVING_STATE;
			}
		}
		else
		{
			if ( SHOWING_STATE == state ) 
			{
				TweenUtils.entityTo( drawerEntity, Spatial, transitionDuration(false), tweenVars(this.directionOfTravel, false));
				drawerState = DEPARTING_STATE;
			}
		}
	}

	private function transitionDuration(entering:Boolean):Number 
	{
		var result:Number;
		if (entering) {
			result = isNaN(entranceDuration) ? DEFAULT_DURATION : entranceDuration;
		} else {
			result = isNaN(exitDuration) ? DEFAULT_DURATION : exitDuration;
		}
		return result;
	}

	private function tweenVars(direction:uint, entering:Boolean):Object {
		var lerp:Function = entering ? entranceLerp : exitLerp;
		if (lerp == null) {
			lerp = DEFAULT_LERP;
		}
		var result:Object = {
			ease:		lerp,
			onComplete:	entering ? onArrival : onDeparture
		};
		if (HORIZONTAL_TRAVEL == direction) {
			result.x = entering ? onscreenX : offscreenX;
		} else {
			result.y = entering ? onscreenY : offscreenY;
		}
		return result;
	}

	private function onArrival():void {
		drawerState = SHOWING_STATE;
		if (entranceCallback != null) {
			entranceCallback();
		}
	}

	private function onDeparture():void {
		drawerState = HIDDEN_STATE;
		if (exitCallback != null) {
			exitCallback();
		}
	}

}

}
