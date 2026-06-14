#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define M_PI 3.14159265358979323846
#define GAMMA 1.4
#define R_GAS 1.0
#define CFL 1
#define Nf 500
#define FLUID 0
#define SOLID 1
#define SBL 0.6
#define SBH 0.2

/* Box-Muller: standard normal random number, mean 0 and variance 1 */
float rand_normal() {
    float u1 = (float)rand() / RAND_MAX;
    float u2 = (float)rand() / RAND_MAX;
    if (u1 < 1e-10) u1 = 1e-10;
    return sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s NX NY T_END\n", argv[0]);
        return 1;
    }

    int NX = atoi(argv[1]);
    int NY = atoi(argv[2]);
    float t_max = atof(argv[3]);
    float DX = 3.0 / NX;
    float DY = 1.0 / NY;
    int size_x = NX + 2; //1~NX
    int size_y = NY + 2;
    int total_size = size_x * size_y;

    int step_i = (int)(SBL / DX);
    int step_j = (int)(SBH / DY);

    float *rho      = (float *)malloc(total_size * sizeof(float));
    float *rhou     = (float *)malloc(total_size * sizeof(float));
    float *rhov     = (float *)malloc(total_size * sizeof(float));
    float *E        = (float *)malloc(total_size * sizeof(float));
    float *pressure = (float *)malloc(total_size * sizeof(float));
    float *u        = (float *)malloc(total_size * sizeof(float));
    float *v        = (float *)malloc(total_size * sizeof(float));
    float *temp     = (float *)malloc(total_size * sizeof(float));

    float *rho_new  = (float *)malloc(total_size * sizeof(float));
    float *rhou_new = (float *)malloc(total_size * sizeof(float));
    float *rhov_new = (float *)malloc(total_size * sizeof(float));
    float *E_new    = (float *)malloc(total_size * sizeof(float));
    int *solid      = (int *)malloc(total_size * sizeof(int));
    float rho_in = 1.4;
    float p_in = 1.0;
    float u_in = 3.0;
    float v_in = 0.0;
    //總能量密度公式
    float E_in = p_in / (GAMMA - 1.0) + 0.5 * rho_in * (u_in * u_in + v_in * v_in);

    srand(2026); //srand(time(NULL))

    for (int i = 0; i < size_x; i++) {
        for (int j = 0; j < size_y; j++) {
            int idx = i * size_y + j;

            solid[idx] = FLUID;
            rho[idx] = rho_in;
            rhou[idx] = rho_in * u_in;
            rhov[idx] = rho_in * v_in;
            E[idx] = E_in;
            u[idx] = u_in;
            v[idx] = v_in;
            pressure[idx] = p_in;
            temp[idx] = p_in / (rho_in * R_GAS); 

            if (i >= 1 && i <= NX && j >= 1 && j <= NY) {
                float x = (i - 0.5) * DX;
                float y = (j - 0.5) * DY;

                if (x >= SBL && y <= SBH) {
                    solid[idx] = SOLID;
                    rho[idx] = 0.0;
                    rhou[idx] = 0.0;
                    rhov[idx] = 0.0;
                    E[idx] = 0.0;
                    pressure[idx] = 0.0;
                    u[idx] = 0.0;
                    v[idx] = 0.0;
                    temp[idx] = 0.0;
                }
            }

            rho_new[idx] = rho[idx];
            rhou_new[idx] = rhou[idx];
            rhov_new[idx] = rhov[idx];
            E_new[idx] = E[idx];
        }
    }

    float *cx_pool = (float *)malloc(Nf * sizeof(float));
    float *cy_pool = (float *)malloc(Nf * sizeof(float));
    float t = 0.0;
    int step = 0;

    while (t < t_max) {
        /* left Mach 3 inflow */
        for (int j = 1; j <= NY; j++) {
            int idx = j;
            rho[idx] = rho_in;
            rhou[idx] = rho_in * u_in;
            rhov[idx] = rho_in * v_in;
            E[idx] = E_in;
            u[idx] = u_in;
            v[idx] = v_in;
            pressure[idx] = p_in;
            temp[idx] = p_in / (rho_in * R_GAS);
        }

        /* right outflow */
        for (int j = 1; j <= NY; j++) {
            int idx_g = (NX + 1) * size_y + j;
            int idx_i = NX * size_y + j;
            rho[idx_g]      = rho[idx_i];
            rhou[idx_g]     = rhou[idx_i];
            rhov[idx_g]     = rhov[idx_i];
            E[idx_g]        = E[idx_i];
            pressure[idx_g] = pressure[idx_i];
            u[idx_g]        = u[idx_i];
            v[idx_g]        = v[idx_i];
            temp[idx_g]     = temp[idx_i];
        }

        /* upper reflective wall */
        for (int i = 1; i <= NX; i++) {
            int idx_g = i * size_y + (NY + 1);
            int idx_i = i * size_y + NY;
            rho[idx_g]      = rho[idx_i];
            rhou[idx_g]     = rhou[idx_i];
            rhov[idx_g]     = -rhov[idx_i];
            E[idx_g]        = E[idx_i];
            pressure[idx_g] = pressure[idx_i];
            u[idx_g]        = u[idx_i];
            v[idx_g]        = -v[idx_i];
            temp[idx_g]     = temp[idx_i];
        }

        /* lower reflective wall and step top wall */
        for (int i = 1; i <= NX; i++) {
            if (i <= step_i) {
                int idx_g = i * size_y;
                int idx_i = i * size_y + 1;
                rho[idx_g]      = rho[idx_i];
                rhou[idx_g]     = rhou[idx_i];
                rhov[idx_g]     = -rhov[idx_i];
                E[idx_g]        = E[idx_i];
                pressure[idx_g] = pressure[idx_i];
                u[idx_g]        = u[idx_i];
                v[idx_g]        = -v[idx_i];
                temp[idx_g]     = temp[idx_i];
            } else {
                int idx_g = i * size_y + step_j;
                int idx_i = i * size_y + (step_j + 1);
                rho[idx_g]      = rho[idx_i];
                rhou[idx_g]     = rhou[idx_i];
                rhov[idx_g]     = -rhov[idx_i];
                E[idx_g]        = E[idx_i];
                pressure[idx_g] = pressure[idx_i];
                u[idx_g]        = u[idx_i];
                v[idx_g]        = -v[idx_i];
                temp[idx_g]     = temp[idx_i];
            }
        }

        /* vertical wall at the step front */
        for (int j = 1; j <= step_j; j++) {
            int idx_g = (step_i + 1) * size_y + j;
            int idx_i = step_i * size_y + j;
            rho[idx_g]      = rho[idx_i];
            rhou[idx_g]     = -rhou[idx_i];
            rhov[idx_g]     = rhov[idx_i];
            E[idx_g]        = E[idx_i];
            pressure[idx_g] = pressure[idx_i];
            u[idx_g]        = -u[idx_i];
            v[idx_g]        = v[idx_i];
            temp[idx_g]     = temp[idx_i];
        }

        float max_v = 0.0;
        for (int i = 1; i <= NX; i++) {
            for (int j = 1; j <= NY; j++) {
                int idx = i * size_y + j;
                if (solid[idx] == SOLID) continue;

                float thermal_c = 3 * sqrt(R_GAS * temp[idx]);
                float vx_max = fabs(u[idx]) + thermal_c;
                float vy_max = fabs(v[idx]) + thermal_c;

                if (vx_max > max_v) max_v = vx_max;
                if (vy_max > max_v) max_v = vy_max;
            }
        }

        if (max_v < 1e-12) max_v = 1e-12;

        float dt = CFL * fmin(DX, DY) / max_v;
        if (t + dt > t_max) dt = t_max - t;

        for (int pp = 0; pp < Nf; pp++) {
            cx_pool[pp] = rand_normal();
            cy_pool[pp] = rand_normal();
        }

        float mean_x = 0.0;
        float mean_y = 0.0;
        for (int pp = 0; pp < Nf; pp++) {
            mean_x += cx_pool[pp];
            mean_y += cy_pool[pp];
        }
        mean_x /= Nf;
        mean_y /= Nf;

        float var_x = 0.0;
        float var_y = 0.0;
        for (int pp = 0; pp < Nf; pp++) {
            cx_pool[pp] -= mean_x;
            cy_pool[pp] -= mean_y;
            var_x += cx_pool[pp] * cx_pool[pp];
            var_y += cy_pool[pp] * cy_pool[pp];
        }
        var_x /= Nf;
        var_y /= Nf;

        float std_x = sqrt(var_x);
        float std_y = sqrt(var_y);
        if (std_x < 1e-6) std_x = 1e-6;
        if (std_y < 1e-6) std_y = 1e-6;

        for (int pp = 0; pp < Nf; pp++) {
            cx_pool[pp] /= std_x;
            cy_pool[pp] /= std_y;
        }

        for (int i = 0; i < size_x; i++) {
            for (int j = 0; j < size_y; j++) {
                int idx = i * size_y + j;
                rho_new[idx] = 0.0;
                rhou_new[idx] = 0.0;
                rhov_new[idx] = 0.0;
                E_new[idx] = 0.0;
            }
        }

        for (int i = 0; i <= NX; i++) {
            for (int j = 1; j <= NY; j++) {
                int is_inflow_source = (i == 0);
                int is_physical_cell = (i >= 1 && i <= NX);
                int src_idx = i * size_y + j;

                if (is_physical_cell) {
                    if (solid[src_idx] == SOLID) continue;
                    if (rho[src_idx] <= 1e-12) continue;
                    if (pressure[src_idx] <= 1e-12) continue;
                }

                float rho_s, u_s, v_s, p_s, T_s;
                if (is_inflow_source) {
                    rho_s = rho_in;
                    u_s = u_in;
                    v_s = v_in;
                    p_s = p_in;
                    T_s = p_s / (rho_s * R_GAS);
                } else {
                    rho_s = rho[src_idx];
                    u_s = u[src_idx];
                    v_s = v[src_idx];
                    p_s = pressure[src_idx];
                    T_s = temp[src_idx];
                }

                float m_p = rho_s / Nf; //質量
                float sqrt_RT = sqrt(R_GAS * T_s);
                float full_internal_e = p_s / ((GAMMA - 1.0) * rho_s); //單位質量內能
                float extra_internal_e = full_internal_e - R_GAS * T_s; //總能量密度
                if (extra_internal_e < 0.0) extra_internal_e = 0.0;

                for (int pp = 0; pp < Nf; pp++) {
                    float p_vx = u_s + sqrt_RT * cx_pool[pp];
                    float p_vy = v_s + sqrt_RT * cy_pool[pp];
                    float rx = ((float)rand() / RAND_MAX) * DX;
                    float ry = ((float)rand() / RAND_MAX) * DY;
                    float x0, y0;

                    if (is_inflow_source) {
                        x0 = -DX + rx;
                        y0 = (j - 1) * DY + ry;
                    } else {
                        x0 = (i - 1) * DX + rx;
                        y0 = (j - 1) * DY + ry;
                    }

                    float x1 = x0 + p_vx * dt;
                    float y1 = y0 + p_vy * dt;
                    
                    if(y1>1.0){
                        y1=2.0-y1;
                        p_vy=-p_vy;
                    }

                    if (p_vy < 0.0f && y0 > 0.0f && y1 < 0.0f) {
                        float t_hit = (0.0f - y0) / p_vy;
                        float x_hit = x0 + p_vx * t_hit;

                        if (x_hit < SBL) {
                            y1 = -y1;
                            p_vy = -p_vy;
                        }
                    }

                    //階梯
                    if (p_vy < 0.0f && y0 > SBH && y1 < SBH) {
                        float t_hit = (SBH - y0) / p_vy;
                        float x_hit = x0 + p_vx * t_hit;

                        if (x_hit >= SBL) {
                            y1 = 2.0f * SBH - y1;
                            p_vy = -p_vy;
                        }
                    }
                   
                    //垂直牆
                    if(p_vx>0.0 && x0<SBL && x1> SBL){
                        float t_hit = (SBL-x0)/p_vx;
                        float y_hit = y0+p_vy*t_hit;
                        if(y_hit>=0.0 && y_hit<=SBH){
                            x1=2.0*SBL-x1;
                            p_vx=-p_vx;
                        }
                    }
                    //判斷落在哪個CELL
                    int target_i = (int)floor(x1 / DX) + 1;
                    int target_j = (int)floor(y1 / DY) + 1;

                    if (target_i < 1) continue;
                    if (target_i > NX) continue;
                    if (target_j<1) continue;
                    if (target_j>NY) continue;
                    /*
                    if (target_j < 1 || target_j > NY) {
                        target_i = i;
                        target_j = j;
                        p_vy = -p_vy;
                    }*/

                    int tgt_idx = target_i * size_y + target_j;
                    if (solid[tgt_idx] == SOLID) {
                        if (is_inflow_source) continue;
                    }
                    /*
                    if (solid[tgt_idx] == SOLID) {
                        if (is_inflow_source) continue;

                        int old_target_i = target_i;
                        int old_target_j = target_j;

                        target_i = i;
                        target_j = j;
                        tgt_idx = src_idx;

                        if (old_target_i != i) p_vx = -p_vx;
                        if (old_target_j != j) p_vy = -p_vy;
                    }*/

                    float particle_E = m_p * (0.5 * (p_vx * p_vx + p_vy * p_vy) + extra_internal_e);

                    rho_new[tgt_idx] += m_p;
                    rhou_new[tgt_idx] += m_p * p_vx;
                    rhov_new[tgt_idx] += m_p * p_vy;
                    E_new[tgt_idx] += particle_E;
                }
            }
        }

        for (int i = 1; i <= NX; i++) {
            for (int j = 1; j <= NY; j++) {
                int idx = i * size_y + j;

                if (solid[idx] == SOLID) {
                    rho[idx]  = 0.0;
                    rhou[idx] = 0.0;
                    rhov[idx] = 0.0;
                    E[idx]    = 0.0;
                    u[idx]    = 0.0;
                    v[idx]    = 0.0;
                    pressure[idx] = 0.0;
                    temp[idx] = 0.0;
                    continue;
                }

                rho[idx]  = rho_new[idx];
                rhou[idx] = rhou_new[idx];
                rhov[idx] = rhov_new[idx];
                E[idx]    = E_new[idx];

                if (rho[idx] < 1e-8) rho[idx] = 1e-8;

                u[idx] = rhou[idx] / rho[idx];
                v[idx] = rhov[idx] / rho[idx];

                float ke_density = 0.5 * rho[idx] * (u[idx] * u[idx] + v[idx] * v[idx]);
                pressure[idx] = (GAMMA - 1.0) * (E[idx] - ke_density);

                if (pressure[idx] < 1e-8) {
                    pressure[idx] = 1e-8;
                    E[idx] = pressure[idx] / (GAMMA - 1.0) + ke_density;
                }
                temp[idx] = pressure[idx] / (rho[idx] * R_GAS);
            }
        }

        t += dt;
        step++;
        if (step % 200 == 0) {
            printf("Step: %d, Time: %.4f / %.2f\n", step, t, t_max);
        }
    }

    FILE *fp = fopen("results.txt", "w");

    for (int j = 1; j <= NY; j++) {
        for (int i = 1; i <= NX; i++) {
            int id = i * size_y + j;
            float x = (i - 0.5) * DX;
            float y = (j - 0.5) * DY;

            fprintf(fp, "%f %f %f %f %f %f %d\n",
                    x, y,
                    rho[id],
                    u[id],
                    v[id],
                    pressure[id],
                    solid[id]);
        }
    }

    fclose(fp);
    printf("results.txt done\n");

    free(rho);
    free(rhou);
    free(rhov);
    free(E);
    free(pressure);
    free(u);
    free(v);
    free(temp);
    free(rho_new);
    free(rhou_new);
    free(rhov_new);
    free(E_new);
    free(cx_pool);
    free(cy_pool);
    free(solid);

    return 0;
}
