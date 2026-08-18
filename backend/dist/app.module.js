"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const user_entity_1 = require("./entities/user.entity");
const message_entity_1 = require("./entities/message.entity");
const contact_entity_1 = require("./entities/contact.entity");
const auth_service_1 = require("./modules/auth/auth.service");
const auth_controller_1 = require("./modules/auth/auth.controller");
const jwt_strategy_1 = require("./modules/auth/jwt.strategy");
const users_service_1 = require("./modules/users/users.service");
const users_controller_1 = require("./modules/users/users.controller");
const messages_service_1 = require("./modules/messages/messages.service");
const messages_controller_1 = require("./modules/messages/messages.controller");
const chat_gateway_1 = require("./gateways/chat.gateway");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            typeorm_1.TypeOrmModule.forRoot({
                type: 'sqlite',
                database: 'gizmo.sqlite',
                entities: [user_entity_1.User, message_entity_1.Message, contact_entity_1.Contact],
                synchronize: true,
            }),
            typeorm_1.TypeOrmModule.forFeature([user_entity_1.User, message_entity_1.Message, contact_entity_1.Contact]),
            jwt_1.JwtModule.register({
                secret: process.env.JWT_SECRET || 'gizmo-super-secret-jwt-key-2026',
                signOptions: { expiresIn: '30d' },
            }),
        ],
        controllers: [auth_controller_1.AuthController, users_controller_1.UsersController, messages_controller_1.MessagesController],
        providers: [auth_service_1.AuthService, jwt_strategy_1.JwtStrategy, users_service_1.UsersService, messages_service_1.MessagesService, chat_gateway_1.ChatGateway],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map