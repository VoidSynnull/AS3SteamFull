package game.data {

import game.util.ProxyUtils;
import game.util.Utils;

public class PlayerLocation {
	public static const AS2_TYPE:uint	= 1;
	public static const AS3_TYPE:uint	= 2;

	public static function nameForType(typeCode:uint):String
	{
		var typeName:String = "unknownType";
	
		switch (typeCode) {
			case PlayerLocation.AS2_TYPE:
				typeName = "AS2";
				break;
			case PlayerLocation.AS3_TYPE:
				typeName = "AS3";
				break;
			default:
				break;
		}
		return typeName;
	}

	private var islandType:uint;
	private var islandName:String;
	private var sceneName:String;
	private var sceneX:Number = NaN;
	private var sceneY:Number = NaN;
	private var playerDirection:String;

	public static function instanceFromInitializer(initObj:Object):PlayerLocation
	{
		var instance:PlayerLocation = new PlayerLocation();
		Utils.overlayObjectProperties(initObj, instance) as PlayerLocation;
trace("your playerlocation comes out to be", instance);
		return instance;
	}

	public static function instanceFromPopURL(url:String):PlayerLocation
	{
		var data:Object = ProxyUtils.parsePopURL(url);
		var instance:PlayerLocation = new PlayerLocation();
		instance.type = AS2_TYPE;
		instance.island		= data.island;
		instance.scene		= data.scene;
		if (!(isNaN(data.playerX) || isNaN(data.playerY))) {
			instance.locX = data.playerX;
			instance.locY = data.playerY;
		}
		instance.direction = data.direction;
		return instance;
	}

	//// CONSTRUCTOR ////

	public function PlayerLocation()
	{
	}

	//// ACCESSORS ////

	public function get type():uint {	return islandType; }
	public function set type(newType:uint):void {	islandType = newType; }

	public function get island():String {	return islandName; }
	public function set island(newName:String):void {	islandName = newName; }

	public function get scene():String {	return sceneName; }
	public function set scene(newName:String):void {	sceneName = newName; }

	public function get locX():Number {	return sceneX; }
	public function set locX(newLoc:Number):void {	sceneX = newLoc; }

	public function get locY():Number {	return sceneY; }
	public function set locY(newLoc:Number):void {	sceneY = newLoc; }

	public function get direction():String {	return playerDirection; }
	public function set direction(newDirection:String):void {	playerDirection = newDirection; }

	public function get popURL():String
	{
		if (AS2_TYPE == type) {
			if (island && scene) {
				var url:String = 'pop://gameplay/' + island + '/' + scene;
				if (!(isNaN(locX) || isNaN(locY))) {
					url += '/' + locX + '/' + locY;
					if (direction) {
						url += '/' + direction;
					}
				}
			}
			return url;
		}
		return null;
	}

	//// PUBLIC METHODS ////

	public function toString():String
	{
		var s:String = '[PlayerLocation';
		s += ' type:' + PlayerLocation.nameForType(type);
		s += ' island:' + island;
		s += ' scene:' + scene;
		if (!(isNaN(locX) || isNaN(locY))) {
			s += ' x:' + locX + ' y:' + locY;
		}
		if (direction) {
			s += ' dir:' + direction;
		}
		s += ']';
		return s;
	}

}

}
